<script module lang="ts">
  import MarketingLayout from "../layouts/MarketingLayout.svelte";
  export const layout = MarketingLayout;
</script>

<script lang="ts">
  import { staticPages } from "../api";
  import MarketingFooter from "../components/MarketingFooter.svelte";
  import MarketingHeader from "../components/MarketingHeader.svelte";

  let { last_updated }: { last_updated: string } = $props();

  const NAV_LINKS = [
    { href: "#philosophy", label: "Philosophy" },
    {
      href: "https://github.com/Dareto-Dream/DeltaTime",
      label: "GitHub",
      external: true,
    },
  ];
</script>

<svelte:head>
  <title>Terms of Service - Deltatime</title>
</svelte:head>

<div class="min-h-screen w-full bg-darker text-surface-content">
  <MarketingHeader navLinks={NAV_LINKS} ctaLabel="Sign in" />

  <main class="pt-32 pb-24 px-6">
    <div class="max-w-[70ch] mx-auto">
      <h1 class="text-4xl font-bold tracking-tight mb-2">
        Terms of Service
      </h1>
      <p class="text-secondary text-sm mb-12">Last updated: {last_updated}</p>

      <div class="space-y-10 leading-relaxed text-surface-content">
        <section>
          <p>
            These terms govern your use of Deltatime. By creating an account
            or otherwise using the service, you agree to them. If you don't
            agree, please don't use Deltatime.
          </p>
        </section>

        <section>
          <h2 class="text-2xl font-semibold mb-4">What Deltatime is</h2>
          <p>
            Deltatime is a free, independently run coding time tracker,
            built as an open-source fork of
            <a
              href="https://github.com/hackclub/hackatime"
              target="_blank"
              class="text-primary underline">Hackatime</a
            >. It's a personal project, not affiliated with, operated by, or
            endorsed by Hack Club Inc., the operators of
            hackatime.hackclub.com, or WakaTime.
          </p>
        </section>

        <section>
          <h2 class="text-2xl font-semibold mb-4">Accounts</h2>
          <p class="mb-4">
            You're responsible for keeping your credentials (password and/or
            connected accounts) secure, and for anything that happens under
            your account. Please use one account per person and provide
            accurate information - see the
            <a href={staticPages.privacy.path()} class="text-primary underline"
              >Privacy Policy</a
            > for what we do with it.
          </p>
        </section>

        <section>
          <h2 class="text-2xl font-semibold mb-4">Acceptable use</h2>
          <p class="mb-4">You agree not to:</p>
          <ul class="list-disc pl-6 space-y-3">
            <li>
              Submit fabricated, falsified, or automated heartbeat data to
              inflate your stats or game leaderboards and badges.
            </li>
            <li>
              Abuse the API - this includes exceeding reasonable rate limits,
              scraping, or attempting to access data you're not authorized
              to see.
            </li>
            <li>
              Attempt to bypass access controls, interfere with the
              operation of the service, or access another user's account
              without permission.
            </li>
            <li>
              Upload or submit illegal, infringing, or abusive content.
            </li>
            <li>Use Deltatime to violate any applicable law.</li>
          </ul>
          <p class="mt-4">
            Accounts that violate these rules, or that undermine leaderboard
            integrity, may be flagged, restricted, or removed.
          </p>
        </section>

        <section>
          <h2 class="text-2xl font-semibold mb-4">Your content</h2>
          <p>
            You retain ownership of the data you submit, including your
            coding activity. By using Deltatime, you grant us the license
            needed to store, process, and display that data as part of
            running the service - for example, showing your stats on your
            public profile if you have that enabled.
          </p>
        </section>

        <section>
          <h2 class="text-2xl font-semibold mb-4">
            API keys and third-party tools
          </h2>
          <p>
            Your API key works like a password - keep it secret, and don't
            share it. You're responsible for anything sent to Deltatime
            using your key, including from third-party editor plugins or
            tools you choose to configure with it.
          </p>
        </section>

        <section>
          <h2 class="text-2xl font-semibold mb-4">Service availability</h2>
          <p>
            Deltatime is a personal project, provided free of charge and "as
            is," without any guarantee of uptime, performance, or continued
            availability. Features - and the service itself - may change,
            be interrupted, or be discontinued at any time, ideally with
            reasonable notice when practical.
          </p>
        </section>

        <section>
          <h2 class="text-2xl font-semibold mb-4">
            Termination and deletion
          </h2>
          <p>
            We may suspend or terminate accounts that violate these terms.
            You can delete your own account at any time from
            <a href="/my/settings/privacy" class="text-primary underline"
              >Settings &rarr; Privacy</a
            >; see the
            <a href={staticPages.privacy.path()} class="text-primary underline"
              >Privacy Policy</a
            > for how that process works.
          </p>
        </section>

        <section>
          <h2 class="text-2xl font-semibold mb-4">
            Disclaimer of warranties
          </h2>
          <p>
            Deltatime is provided "as is" and "as available," without
            warranties of any kind, whether express or implied, including
            (without limitation) warranties of merchantability, fitness for
            a particular purpose, or non-infringement.
          </p>
        </section>

        <section>
          <h2 class="text-2xl font-semibold mb-4">
            Limitation of liability
          </h2>
          <p>
            To the fullest extent permitted by law, the operator of
            Deltatime won't be liable for any indirect, incidental, special,
            or consequential damages arising from your use of, or inability
            to use, the service.
          </p>
        </section>

        <section>
          <h2 class="text-2xl font-semibold mb-4">Changes to these terms</h2>
          <p>
            We may update these terms from time to time. Continuing to use
            Deltatime after a change means you accept the updated terms.
            Material changes will be reflected here with a new "last
            updated" date.
          </p>
        </section>

        <section>
          <h2 class="text-2xl font-semibold mb-4">Contact</h2>
          <p>
            Questions about these terms? Reach out at
            <a
              href="mailto:dare.to.0ream@gmail.com"
              class="text-primary underline">dare.to.0ream@gmail.com</a
            >.
          </p>
        </section>

        <section class="pt-4">
          <a href={staticPages.privacy.path()} class="text-primary underline text-sm"
            >Read the Privacy Policy &rarr;</a
          >
        </section>
      </div>
    </div>
  </main>

  <MarketingFooter />
</div>
