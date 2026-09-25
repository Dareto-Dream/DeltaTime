<script lang="ts">
  import Button from "../../components/Button.svelte";
  import ScreenHeader from "./components/ScreenHeader.svelte";
  import SetupCodeBlock from "./components/SetupCodeBlock.svelte";

  interface Props {
    apiKey: string;
    onDone: () => void;
  }

  let { apiKey, onDone }: Props = $props();

  const setKeyCommand = `/deltatime setkey ${apiKey}`;

  const steps = [
    {
      title: "Install Fabric",
      body: "Install Fabric for Minecraft 26.3.",
      linkUrl: "https://fabricmc.net/use/",
      linkLabel: "fabricmc.net/use",
    },
    {
      title: "Install the mod",
      body: "Download the Deltatime mod and drop it into your mods folder.",
      linkUrl: "https://cdn.deltavdevs.com/deltatime-1.0.0.jar",
      linkLabel: "cdn.deltavdevs.com/deltatime-1.0.0.jar",
    },
  ];
</script>

<div class="space-y-8 sm:space-y-10">
  <ScreenHeader
    emoji="/images/emojis/ms-cool.svg"
    title="Minecraft setup"
    subtitle="Track the time you spend playing and building in Minecraft."
  />

  <div class="mx-auto max-w-2xl space-y-6 text-left">
    <ol class="space-y-4">
      {#each steps as step, index (step.title)}
        <li class="flex items-start gap-3">
          <span
            class="flex size-6 shrink-0 items-center justify-center rounded-full bg-surface-300 text-xs font-semibold text-surface-content"
          >
            {index + 1}
          </span>
          <span class="text-sm text-secondary">
            {step.body}
            <br />
            <a
              href={step.linkUrl}
              target="_blank"
              rel="noreferrer"
              class="font-medium text-primary underline underline-offset-4 break-all"
            >
              {step.linkLabel}
            </a>
          </span>
        </li>
      {/each}
      <li class="flex items-start gap-3">
        <span
          class="flex size-6 shrink-0 items-center justify-center rounded-full bg-surface-300 text-xs font-semibold text-surface-content"
        >
          3
        </span>
        <span class="text-sm text-secondary">
          Launch Minecraft with the Fabric profile, then run this command in
          chat to link your account:
        </span>
      </li>
    </ol>

    <SetupCodeBlock code={setKeyCommand} />

    <p
      class="rounded-lg border border-primary/40 bg-primary/10 px-4 py-3 text-sm text-secondary"
    >
      Join the server with
      <span class="font-mono font-medium text-surface-content"
        >turkiye.deltavdevs.com</span
      >. Time is recorded under the address you connect with, and Synthcity
      only counts time under turkiye.deltavdevs.com.
    </p>
  </div>

  <div class="text-center">
    <Button variant="dark" size="lg" onclick={onDone}>I'm done!</Button>
  </div>
</div>
