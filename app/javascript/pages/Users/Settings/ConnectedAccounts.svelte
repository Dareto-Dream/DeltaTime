<script module lang="ts">
  import settingsLayout from "./layout";
  export const layout = settingsLayout;
</script>

<script lang="ts">
  import { Form } from "@inertiajs/svelte";
  import Button from "../../../components/Button.svelte";
  import Modal from "../../../components/Modal.svelte";
  import SectionCard from "./components/SectionCard.svelte";
  import ModalActions from "./components/ModalActions.svelte";
  import { sessions } from "../../../api";

  type Props = {
    ward: {
      enabled: boolean;
      connected: boolean;
      name?: string | null;
    };
    has_password: boolean;
    google: {
      connected: boolean;
      name?: string | null;
    };
    github: {
      connected: boolean;
      username?: string | null;
      profile_url?: string | null;
    };
  };

  let { ward, has_password, google, github }: Props = $props();

  let unlinkGoogleModalOpen = $state(false);
  let unlinkGithubModalOpen = $state(false);
  let removePasswordModalOpen = $state(false);
</script>

<svelte:head>
  <title>Connected Accounts - Deltatime Settings</title>
</svelte:head>

{#if ward.enabled}
  <SectionCard
    id="user_ward_account"
    title="Ward"
    description="Ward is your DeltaVDevs account: one sign-in for DeltaTime, the blog and SynthCity."
    hasBody
  >
    {#if ward.connected}
      <div
        class="rounded-md border border-surface-200 bg-darker px-3 py-3 text-sm text-surface-content flex items-center gap-2"
      >
        <img src="/ward.svg" alt="" class="h-5 w-5 rounded" />
        Linked{ward.name ? ` as ${ward.name}` : ""}. This is how you sign in.
      </div>
      {#if google.connected || has_password}
        <p class="mt-3 text-sm text-muted">
          Now remove your old sign-ins: unlink Google{has_password
            ? " and remove your password"
            : ""}. Keep GitHub if you use project links.
        </p>
      {/if}
    {:else}
      <div
        class="rounded-md border border-primary/50 bg-primary/10 px-3 py-3 text-sm text-surface-content"
      >
        Link your Ward account, then remove your old Google sign-in and
        password. Your stats and history stay right where they are.
      </div>
    {/if}

    {#snippet footer()}
      {#if !ward.connected}
        <Button href={sessions.wardNew.path()} native class="rounded-md"
          >Link Ward</Button
        >
      {:else if has_password}
        <Button
          type="button"
          variant="surface"
          class="rounded-md"
          onclick={() => (removePasswordModalOpen = true)}
        >
          Remove password
        </Button>
      {/if}
    {/snippet}
  </SectionCard>
{/if}

<SectionCard
  id="user_google_account"
  title="Connected Google Account"
  description="Link Google to sign in without a password."
  hasBody={Boolean(google.connected && google.name)}
>
  {#if google.connected && google.name}
    <div
      class="rounded-md border border-surface-200 bg-darker px-3 py-3 text-sm text-surface-content"
    >
      Connected as {google.name}
    </div>
  {/if}

  {#snippet footer()}
    {#if google.connected}
      <Button href={sessions.googleNew.path()} native class="rounded-md"
        >Reconnect Google</Button
      >
      <Button
        type="button"
        variant="surface"
        class="rounded-md"
        onclick={() => (unlinkGoogleModalOpen = true)}
      >
        Unlink Google
      </Button>
    {:else}
      <Button href={sessions.googleNew.path()} native class="rounded-md"
        >Connect Google</Button
      >
    {/if}
  {/snippet}
</SectionCard>

<SectionCard
  id="user_github_account"
  title="Connected GitHub Account"
  description="Connect GitHub to show project links in dashboards and leaderboards."
  hasBody={Boolean(github.connected && github.username)}
>
  {#if github.connected && github.username}
    <div
      class="rounded-md border border-surface-200 bg-darker px-3 py-3 text-sm text-surface-content"
    >
      Connected as
      <a href={github.profile_url || "#"} target="_blank" class="underline"
        >@{github.username}</a
      >
    </div>
  {/if}

  {#snippet footer()}
    {#if github.connected && github.username}
      <Button href={sessions.githubNew.path()} native class="rounded-md"
        >Reconnect GitHub</Button
      >
      <Button
        type="button"
        variant="surface"
        class="rounded-md"
        onclick={() => (unlinkGithubModalOpen = true)}
      >
        Unlink GitHub
      </Button>
    {:else}
      <Button href={sessions.githubNew.path()} native class="rounded-md"
        >Connect GitHub</Button
      >
    {/if}
  {/snippet}
</SectionCard>

<Modal
  bind:open={unlinkGoogleModalOpen}
  title="Unlink Google account?"
  description="You'll need another way to sign in (GitHub or email + password) once this is unlinked."
  maxWidth="max-w-md"
  hasActions
>
  {#snippet actions()}
    <ModalActions onCancel={() => (unlinkGoogleModalOpen = false)}>
      {#snippet confirm()}
        <Form
          action={sessions.googleUnlink.path()}
          method="delete"
          class="m-0"
          options={{ preserveScroll: true }}
        >
          <Button
            type="submit"
            variant="primary"
            class="h-10 w-full text-on-primary"
          >
            Unlink Google
          </Button>
        </Form>
      {/snippet}
    </ModalActions>
  {/snippet}
</Modal>

<Modal
  bind:open={unlinkGithubModalOpen}
  title="Unlink GitHub account?"
  description="GitHub-based features will stop until you reconnect."
  maxWidth="max-w-md"
  hasActions
>
  {#snippet actions()}
    <ModalActions onCancel={() => (unlinkGithubModalOpen = false)}>
      {#snippet confirm()}
        <Form
          action={sessions.githubUnlink.path()}
          method="delete"
          class="m-0"
          options={{ preserveScroll: true }}
        >
          <Button
            type="submit"
            variant="primary"
            class="h-10 w-full text-on-primary"
          >
            Unlink GitHub
          </Button>
        </Form>
      {/snippet}
    </ModalActions>
  {/snippet}
</Modal>

<Modal
  bind:open={removePasswordModalOpen}
  title="Remove your password?"
  description="You'll sign in with Ward from now on. Email + password sign-in stops working for this account."
  maxWidth="max-w-md"
  hasActions
>
  {#snippet actions()}
    <ModalActions onCancel={() => (removePasswordModalOpen = false)}>
      {#snippet confirm()}
        <Form
          action={sessions.removePassword.path()}
          method="delete"
          class="m-0"
          options={{ preserveScroll: true }}
        >
          <Button
            type="submit"
            variant="primary"
            class="h-10 w-full text-on-primary"
          >
            Remove password
          </Button>
        </Form>
      {/snippet}
    </ModalActions>
  {/snippet}
</Modal>
