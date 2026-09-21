<script lang="ts">
  import Button from "../../../components/Button.svelte";
  import { sessions } from "../../../api";
  import Github from "hcicons-svelte/github-fill";

  let {
    sign_in_email,
    csrf_token,
    continue_param,
  }: {
    sign_in_email: boolean;
    csrf_token: string;
    redirect_to?: string;
    continue_param?: string | null;
  } = $props();

  const query = $derived(
    continue_param ? { query: { continue: continue_param } } : undefined,
  );
  const googleAuthPath = $derived(
    query ? sessions.googleNew.path(query) : sessions.googleNew.path(),
  );
  const githubAuthPath = $derived(
    query ? sessions.githubNew.path(query) : sessions.githubNew.path(),
  );

  let mode: "login" | "signup" = $state(sign_in_email ? "login" : "signup");
  const formAction = $derived(
    mode === "login" ? sessions.login.path() : sessions.signup.path(),
  );
</script>

<div class="w-full max-w-md space-y-4">
  <a
    href={googleAuthPath}
    class="w-full flex items-center justify-center gap-3 px-6 py-3.5 rounded-xl bg-primary text-on-primary font-medium hover:opacity-90 transition-all"
  >
    <svg class="h-5 w-5" viewBox="0 0 24 24">
      <path
        fill="currentColor"
        d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z"
      />
      <path
        fill="currentColor"
        d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
      />
      <path
        fill="currentColor"
        d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
      />
      <path
        fill="currentColor"
        d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
      />
    </svg>
    <span>Sign in with Google</span>
  </a>

  <a
    href={githubAuthPath}
    class="w-full flex items-center justify-center gap-3 px-6 py-3.5 rounded-xl bg-surface border border-surface-200 text-surface-content font-medium hover:bg-surface-100 transition-all"
  >
    <Github size={20} />
    <span>Sign in with GitHub</span>
  </a>

  <div class="flex items-center gap-4 py-1">
    <div class="flex-1 h-px bg-surface-200"></div>
    <span class="text-xs text-muted uppercase tracking-wider">or</span>
    <div class="flex-1 h-px bg-surface-200"></div>
  </div>

  <form method="post" action={formAction} class="space-y-3">
    <input type="hidden" name="authenticity_token" value={csrf_token} />
    {#if continue_param}
      <input type="hidden" name="continue" value={continue_param} />
    {/if}
    <input
      type="email"
      name="email"
      placeholder="you@email.com"
      required
      class="w-full bg-surface text-surface-content placeholder-muted rounded-xl py-3.5 px-4 focus:outline-none focus:ring-2 focus:ring-primary/50 transition-all border border-surface-200 focus:border-primary text-sm"
    />
    <input
      type="password"
      name="password"
      placeholder="Password"
      minlength="8"
      required
      class="w-full bg-surface text-surface-content placeholder-muted rounded-xl py-3.5 px-4 focus:outline-none focus:ring-2 focus:ring-primary/50 transition-all border border-surface-200 focus:border-primary text-sm"
    />
    <Button
      type="submit"
      unstyled
      class="w-full px-5 py-3.5 bg-surface border border-primary text-primary rounded-xl hover:bg-primary hover:text-on-primary transition-all text-sm font-medium"
    >
      {mode === "login" ? "Sign in" : "Create account"}
    </Button>
  </form>

  <p class="text-center text-sm text-muted">
    {#if mode === "login"}
      Don't have an account?
      <button
        type="button"
        class="text-primary underline"
        onclick={() => (mode = "signup")}
      >
        Create one
      </button>
    {:else}
      Already have an account?
      <button
        type="button"
        class="text-primary underline"
        onclick={() => (mode = "login")}
      >
        Sign in
      </button>
    {/if}
  </p>
</div>
