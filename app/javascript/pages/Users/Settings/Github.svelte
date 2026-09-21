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
    github: {
      connected: boolean;
      username?: string | null;
      profile_url?: string | null;
    };
  };

  let { github }: Props = $props();

  let unlinkGithubModalOpen = $state(false);
</script>

<svelte:head>
  <title>GitHub - Deltatime Settings</title>
</svelte:head>

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
