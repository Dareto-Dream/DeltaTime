<script module lang="ts">
  import settingsLayout from "./layout";
  export const layout = settingsLayout;
</script>

<script lang="ts">
  import { Form } from "@inertiajs/svelte";
  import { Icon, Trash } from "svelte-hero-icons";
  import Button from "../../../components/Button.svelte";
  import FormField from "../../../components/FormField.svelte";
  import Select from "../../../components/Select.svelte";
  import TextInput from "../../../components/TextInput.svelte";
  import SectionCard from "./components/SectionCard.svelte";
  import { settingsProfile, sessions } from "../../../api";

  type Props = {
    username_max_length: number;
    display_name_max_length: number;
    user: {
      country_code?: string | null;
      timezone: string;
      display_name: string;
      display_name_override?: string | null;
      username?: string | null;
    };
    options: {
      countries: Array<{ label: string; value: string }>;
      timezones: Array<{ label: string; value: string }>;
    };
    profile_url: string | null;
    emails: Array<{
      email: string;
      source: string;
      can_unlink: boolean;
    }>;
    errors: {
      display_name_override: string[];
      username: string[];
    };
  };

  let {
    username_max_length,
    display_name_max_length,
    user,
    options,
    profile_url,
    emails,
    errors,
  }: Props = $props();
</script>

<svelte:head>
  <title>Profile - Deltatime Settings</title>
</svelte:head>

<SectionCard
  id="user_region"
  title="Region and Timezone"
  description="Use your local region and timezone for accurate dashboards and leaderboards."
>
  <Form
    id="profile-region-form"
    action={settingsProfile.updateRegion.path()}
    method="patch"
    class="space-y-4"
    options={{ preserveScroll: true }}
  >
    <FormField inputId="country_code" label="Country">
      <Select
        id="country_code"
        name="user[country_code]"
        value={user.country_code || ""}
        items={[{ value: "", label: "Select a country" }, ...options.countries]}
      />
    </FormField>

    <FormField wrapperId="user_timezone" inputId="timezone" label="Timezone">
      <Select
        id="timezone"
        name="user[timezone]"
        value={user.timezone}
        items={options.timezones}
      />
    </FormField>
  </Form>

  {#snippet footer()}
    <Button type="submit" variant="primary" form="profile-region-form"
      >Save region settings</Button
    >
  {/snippet}
</SectionCard>

<SectionCard
  id="user_display_name"
  title="Display Name"
  description="This name appears across Deltatime instead of your GitHub, Google, or username."
>
  <Form
    id="profile-display-name-form"
    action={settingsProfile.updateDisplayName.path()}
    method="patch"
    class="space-y-3"
    options={{ preserveScroll: true }}
  >
    <FormField
      inputId="display_name_override"
      label="Display name"
      error={errors.display_name_override[0]}
    >
      <TextInput
        id="display_name_override"
        name="user[display_name_override]"
        value={user.display_name_override || ""}
        maxlength={display_name_max_length}
        placeholder={user.display_name}
      />
    </FormField>
  </Form>

  {#snippet footer()}
    <Button type="submit" variant="primary" form="profile-display-name-form"
      >Save display name</Button
    >
  {/snippet}
</SectionCard>

<SectionCard
  id="user_username"
  title="Username"
  description="This username is used in links and public profile pages."
>
  <Form
    id="profile-username-form"
    action={settingsProfile.updateUsername.path()}
    method="patch"
    class="space-y-3"
    options={{ preserveScroll: true }}
  >
    <FormField inputId="username" label="Username" error={errors.username[0]}>
      <TextInput
        id="username"
        name="user[username]"
        value={user.username || ""}
        maxlength={username_max_length}
        placeholder="your-name"
      />
    </FormField>
  </Form>

  {#if profile_url}
    <p class="text-sm text-muted mt-2">
      Public profile:
      <a
        href={profile_url}
        target="_blank"
        rel="noopener noreferrer"
        class="text-primary underline"
      >
        {profile_url}
      </a>
    </p>
  {/if}

  {#snippet footer()}
    <Button type="submit" variant="primary" form="profile-username-form"
      >Save username</Button
    >
  {/snippet}
</SectionCard>

<SectionCard
  id="user_email_addresses"
  title="Email Addresses"
  description="Add or remove email addresses used for sign-in."
>
  <div class="space-y-2">
    {#if emails.length > 0}
      {#each emails as email}
        <div
          class="flex flex-wrap items-center gap-2 rounded-md border border-surface-200 bg-darker px-3 py-2"
        >
          <div class="grow text-sm text-surface-content">
            <p class="flex items-center gap-2">
              <span>{email.email}</span>
            </p>
            <p class="text-xs text-muted">{email.source}</p>
          </div>
          {#if email.can_unlink}
            <Form
              action={sessions.unlinkEmail.path()}
              method="delete"
              options={{ preserveScroll: true }}
            >
              <input type="hidden" name="email" value={email.email} />
              <Button
                type="submit"
                unstyled
                title="Unlink email"
                aria-label="Unlink email"
                class="inline-flex items-center justify-center rounded-md p-1.5 text-muted transition-colors hover:text-red"
              >
                <Icon src={Trash} size="20" />
              </Button>
            </Form>
          {/if}
        </div>
      {/each}
    {:else}
      <p
        class="rounded-md border border-surface-200 bg-darker px-3 py-2 text-sm text-muted"
      >
        No email addresses are linked.
      </p>
    {/if}
  </div>

  <Form
    id="profile-email-form"
    action={sessions.addEmail.path()}
    method="post"
    class="mt-4 flex flex-col gap-3 sm:flex-row"
    options={{ preserveScroll: true }}
  >
    <TextInput
      type="email"
      name="email"
      required
      placeholder="name@example.com"
      class="grow w-full rounded-md border border-surface-200 bg-input px-3 py-2 text-sm text-surface-content focus:border-primary focus:outline-none"
    />
  </Form>

  {#snippet footer()}
    <Button type="submit" class="rounded-md" form="profile-email-form"
      >Add email</Button
    >
  {/snippet}
</SectionCard>
