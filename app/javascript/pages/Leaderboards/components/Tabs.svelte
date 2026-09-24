<script lang="ts">
  import { Link } from "@inertiajs/svelte";
  import Twemoji from "../../../components/Twemoji.svelte";
  import { tabClass } from "../utils";
  import { leaderboards } from "../../../api";

  let {
    period_type,
    scope,
  }: {
    period_type: string;
    scope: string;
  } = $props();

  const path = (q: Record<string, string | number>) =>
    leaderboards.index.path({ query: q });
  const resetEntries = (current: Record<string, unknown>) => ({
    ...current,
    entries: undefined,
  });
  // DeltaTime: people on DeltaTime. Global: DeltaTime + Hackatime's public board.
  const scopes = [
    { key: "deltatime", label: "DeltaTime" },
    { key: "global", label: "Global" },
  ];
</script>

<div class="inline-flex rounded-full bg-darkless p-1 gap-1">
  {#each scopes as s}
    <Link
      href={path({ period_type, scope: s.key })}
      component="Leaderboards/Index"
      pageProps={(current) => ({ ...resetEntries(current), scope: s.key })}
      class={`${tabClass(scope === s.key)} inline-flex items-center justify-center gap-2`}
      preserveScroll
    >
      {#if s.key === "deltatime"}
        <img
          src="/images/deltatime-icon.svg"
          alt=""
          class="inline-block w-5 h-5 rounded"
        />
      {:else}
        <Twemoji emoji="🌐" alt="Globe" class="inline-block w-5 h-5" />
      {/if}
      <span class="hidden sm:inline">{s.label}</span>
    </Link>
  {/each}
</div>

<div class="inline-flex rounded-full bg-darkless p-1 gap-1">
  {#each [{ key: "daily", short: "24h", long: "Last 24 Hours" }, { key: "last_7_days", short: "7d", long: "Last 7 Days" }] as p}
    <Link
      href={path({ period_type: p.key, scope })}
      component="Leaderboards/Index"
      pageProps={(current) => ({
        ...resetEntries(current),
        period_type: p.key,
      })}
      class={tabClass(period_type === p.key)}
      preserveScroll
    >
      <span class="sm:hidden">{p.short}</span>
      <span class="hidden sm:inline">{p.long}</span>
    </Link>
  {/each}
</div>
