import { requireSupabase } from "./supabaseClient";

function publicSlugFromName(name) {
  const base = String(name || "perfil")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 42);

  return `${base || "perfil"}-${crypto.randomUUID().slice(0, 6)}`;
}

export async function signUpTutor({ email, password, displayName }) {
  const client = requireSupabase();
  const { data, error } = await client.auth.signUp({
    email,
    password,
    options: {
      data: {
        display_name: displayName,
      },
    },
  });

  if (error) throw error;
  return data;
}

export async function signIn({ email, password }) {
  const client = requireSupabase();
  const { data, error } = await client.auth.signInWithPassword({ email, password });

  if (error) throw error;
  return data;
}

export async function sendPasswordReset(email) {
  const client = requireSupabase();
  const { data, error } = await client.auth.resetPasswordForEmail(email, {
    redirectTo: `${window.location.origin}/`,
  });

  if (error) throw error;
  return data;
}

export async function getCurrentProfile() {
  const client = requireSupabase();
  const {
    data: { user },
    error: userError,
  } = await client.auth.getUser();

  if (userError) throw userError;
  if (!user) return null;

  const { data, error } = await client.from("profiles").select("*").eq("id", user.id).single();
  if (error) throw error;
  return data;
}

export async function createPetProfile({
  name,
  species,
  breed,
  birthdayDate,
  birthdayPrecision = "unknown",
  profileType = "private",
  themeId,
  photoUrl,
}) {
  const client = requireSupabase();
  const profile = await getCurrentProfile();

  if (!profile) {
    throw new Error("You must be signed in before creating a pet profile.");
  }

  const { data: pet, error: petError } = await client
    .from("pets")
    .insert({
      name,
      species,
      breed,
      birthday_date: birthdayDate || null,
      birthday_precision: birthdayPrecision,
      public_slug: publicSlugFromName(name),
      profile_type: profileType,
      status: profileType === "private" ? "private" : "community",
      primary_tutor_id: profile.id,
      theme_id: themeId || null,
      photo_url: photoUrl || null,
    })
    .select()
    .single();

  if (petError) throw petError;

  const { error: memberError } = await client.from("pet_members").insert({
    pet_id: pet.id,
    user_id: profile.id,
    role: "tutor principal",
    status: "active",
    permissions: {
      can_edit_profile: true,
      can_write_diary: true,
      can_manage_members: true,
      can_view_private_contacts: true,
      can_view_medical_history: true,
    },
  });

  if (memberError) throw memberError;

  await client.from("journals").insert(
    ["general", "salud", "alimentacion", "medicamentos", "comportamiento", "emergencias"].map(key => ({
      pet_id: pet.id,
      key,
      label: key.charAt(0).toUpperCase() + key.slice(1),
    })),
  );

  return pet;
}

export async function createDraftOrder({
  productId,
  productType,
  profileName,
  setupAnswers,
  themeId,
  paymentMethod,
  deliveryNotes,
}) {
  const client = requireSupabase();
  const profile = await getCurrentProfile();

  if (!profile) {
    throw new Error("You must be signed in before creating an order.");
  }

  const { data: draftProfile, error: draftError } = await client
    .from("draft_profiles")
    .insert({
      created_by: profile.id,
      product_type: productType,
      profile_kind: productType === "tutor_tag" ? "tutor" : "pet",
      profile_name: profileName,
      theme_id: themeId,
      setup_answers: setupAnswers || {},
      state: "pending_payment",
    })
    .select()
    .single();

  if (draftError) throw draftError;

  const { data: order, error: orderError } = await client
    .from("orders")
    .insert({
      user_id: profile.id,
      draft_profile_id: draftProfile.id,
      product_id: productId || null,
      status: "pending_payment",
      payment_method: paymentMethod,
      delivery_notes: deliveryNotes,
      progress: 25,
    })
    .select()
    .single();

  if (orderError) throw orderError;
  return { draftProfile, order };
}

export async function addDiaryEntry({ petId, body, category, priority = "normal", visibility = "private" }) {
  const client = requireSupabase();
  const profile = await getCurrentProfile();

  if (!profile) {
    throw new Error("You must be signed in before adding a diary entry.");
  }

  const { data: entry, error } = await client
    .from("journal_entries")
    .insert({
      pet_id: petId,
      author_id: profile.id,
      body,
      category,
      priority,
      visibility,
    })
    .select()
    .single();

  if (error) throw error;

  await client.from("timeline_events").insert({
    pet_id: petId,
    actor_id: profile.id,
    source_type: "journal_entry",
    source_id: entry.id,
    title: category || "Diario",
    body,
    visibility,
  });

  return entry;
}

export async function sendPublicPetNote({
  petId,
  message,
  visitorName,
  visitorContact,
  approximateLocation,
  happenedAt,
}) {
  const client = requireSupabase();
  const { data, error } = await client
    .from("external_interactions")
    .insert({
      pet_id: petId,
      message,
      visitor_name: visitorName,
      visitor_contact: visitorContact,
      approximate_location: approximateLocation,
      happened_at: happenedAt || null,
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function getCareMailbox() {
  const client = requireSupabase();
  const { data, error } = await client
    .from("care_mailbox")
    .select("*, pets(name, photo_url)")
    .order("created_at", { ascending: false });

  if (error) throw error;
  return data;
}
