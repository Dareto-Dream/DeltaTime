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

  let { google, github }: Props = $props();

  let unlinkGoogleModalOpen = $state(false);
  let unlinkGithubModalOpen = $state(false);
</script>

<svelte:head>
  <title>Connected Accounts - Deltatime Settings</title>
</svelte:head>

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
