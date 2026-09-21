<script module lang="ts">
  import MarketingLayout from "../layouts/MarketingLayout.svelte";
  export const layout = MarketingLayout;
</script>

<script lang="ts">
  import { Link } from "@inertiajs/svelte";
  import { terms } from "../api";
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
  <title>Privacy Policy - Deltatime</title>
</svelte:head>

<div class="min-h-screen w-full bg-darker text-surface-content">
  <MarketingHeader navLinks={NAV_LINKS} ctaLabel="Sign in" />

  <main class="pt-32 pb-24 px-6">
    <div class="max-w-[70ch] mx-auto">
      <h1 class="text-4xl font-bold tracking-tight mb-2">Privacy Policy</h1>
      <p class="text-secondary text-sm mb-12">Last updated: {last_updated}</p>

      <div class="space-y-10 leading-relaxed text-surface-content">
        <section>
          <p>
            Deltatime is an independently run, open-source coding time
            tracker. It's a personal project built as a fork of <a
              href="https://github.com/hackclub/hackatime"
              target="_blank"
              class="text-primary underline">Hackatime</a
            >, and it isn't affiliated with, operated by, or endorsed by Hack
            Club Inc., the operators of hackatime.hackclub.com, or WakaTime.
            This policy explains what data this instance of Deltatime
            collects, how it's used, and the choices you have.
          </p>
          <p class="mt-4 text-secondary text-sm">
            This is a small, personally-operated service, and this policy is
            written in plain language rather than dense legal text. It isn't
            a substitute for professional legal advice, but it accurately
            describes what actually happens with your data in this
            application.
          </p>
        </section>

        <section>
          <h2 class="text-2xl font-semibold mb-4">
            Information we collect
          </h2>
          <ul class="list-disc pl-6 space-y-3">
            <li>
              <strong>Account information.</strong> An email address, and either
              a password (stored as a salted hash - we never see or store your
              plaintext password) or a connected Google/GitHub account. If you
              sign in with Google or GitHub, we receive your account ID, name,
              and profile photo from that provider, and store an access token
              so the connection stays linked.
            </li>
            <li>
              <strong>Coding activity ("heartbeats").</strong> When you code with
              a connected editor plugin, it sends us small pings containing a timestamp,
              the project name, the file or entity you're working in, the programming
              language, editor, operating system, machine identifier, git branch,
              and basic line/cursor statistics. This is the core data the service
              is built around - it's what powers your dashboard, stats, and badges.
            </li>
            <li>
              <strong>Technical data.</strong> Your IP address is used briefly
              to infer a country for regional stats and is not retained in raw
              form - only the resulting country code is kept. We also log basic
              request metadata (like user agent) for security and abuse prevention.
            </li>
            <li>
              <strong>Content you provide.</strong> Your display name, username,
              timezone, country, and any optional profile fields (bio, social links)
              you choose to fill in, plus any goals you set.
            </li>
          </ul>
        </section>

        <section>
          <h2 class="text-2xl font-semibold mb-4">How we use it</h2>
          <ul class="list-disc pl-6 space-y-3">
            <li>To operate the service - your dashboard, stats, streaks, leaderboards, and badges.</li>
            <li>To authenticate you and keep your session signed in.</li>
            <li>
              To send account-related email, such as a welcome message, an
              optional weekly summary, and confirmations for data exports or
              deletion requests.
            </li>
            <li>
              To detect abuse and protect leaderboard integrity (for example,
              flagging heartbeat patterns that look automated or falsified).
            </li>
          </ul>
        </section>

        <section>
          <h2 class="text-2xl font-semibold mb-4">What we share</h2>
          <p class="mb-4">We don't sell your data, to anyone, ever.</p>
          <p class="mb-4">
            Your username, display name, avatar, and coding stats are
            <strong>public by default</strong>
            (this mirrors how WakaTime and Hackatime normally work) unless you
            turn off public stats in
            <Link href="/my/settings/privacy" class="text-primary underline"
              >Settings &rarr; Privacy</Link
            >.
          </p>
          <p class="mb-4">
            A small number of third-party services help run Deltatime:
          </p>
          <ul class="list-disc pl-6 space-y-3">
            <li>
              <strong>Google / GitHub</strong> - only if you choose to connect
              or sign in with one of these, solely for authentication.
            </li>
            <li>
              <strong>Hosting, database, and object storage providers</strong>
              (currently Railway and an S3-compatible storage bucket) - to run
              the application and store uploaded files such as avatars.
            </li>
            <li>
              <strong>MaxMind GeoLite2</strong> - for the IP-to-country lookup
              described above.
            </li>
            <li>
              <strong>Error tracking</strong> (Sentry) - to catch and fix bugs.
              This can include limited technical context about a request, not
              the contents of your coding activity.
            </li>
            <li>
              <strong>Email delivery infrastructure</strong> - to send the
              transactional emails described above.
            </li>
          </ul>
          <p class="mt-4">
            We may also disclose information if required by law, or to
            protect the security or integrity of the service.
          </p>
        </section>

        <section>
          <h2 class="text-2xl font-semibold mb-4">Data retention</h2>
          <p class="mb-4">
            We keep your data for as long as your account is active. You can
            request account deletion at any time from
            <Link href="/my/settings/privacy" class="text-primary underline"
              >Settings &rarr; Privacy</Link
            >. Deletion requests go through a 30-day grace period (so a
            mistaken request can be cancelled); after that, your personal
            information is anonymized and your heartbeats are permanently
            deleted.
          </p>
          <p>
            You can export a copy of your own data at any time from
            <Link
              href="/my/settings/imports_exports"
              class="text-primary underline">Settings &rarr; Imports & Exports</Link
            >.
          </p>
        </section>

        <section>
          <h2 class="text-2xl font-semibold mb-4">Your choices</h2>
          <ul class="list-disc pl-6 space-y-3">
            <li>Turn public stats visibility on or off at any time.</li>
            <li>
              Unlink a connected Google or GitHub account, as long as you
              have another way to sign in.
            </li>
            <li>Rotate or revoke your API key at any time.</li>
            <li>Request an export or deletion of your data at any time.</li>
          </ul>
        </section>

        <section>
          <h2 class="text-2xl font-semibold mb-4">Security</h2>
          <p>
            Passwords are hashed with bcrypt and never stored in plaintext.
            Connected-account access tokens are encrypted at rest. All
            traffic to Deltatime is served over HTTPS.
          </p>
        </section>

        <section>
          <h2 class="text-2xl font-semibold mb-4">Children's privacy</h2>
          <p>
            Deltatime is not directed at children under 13, and we don't
            knowingly collect information from anyone under 13.
          </p>
        </section>

        <section>
          <h2 class="text-2xl font-semibold mb-4">Changes to this policy</h2>
          <p>
            We may update this policy from time to time. Material changes
            will be reflected here with a new "last updated" date.
          </p>
        </section>

        <section>
          <h2 class="text-2xl font-semibold mb-4">Contact</h2>
          <p>
            Questions about this policy or your data? Reach out at <a
              href="mailto:dare.to.0ream@gmail.com"
              class="text-primary underline">dare.to.0ream@gmail.com</a
            >.
          </p>
        </section>

        <section class="pt-4">
          <a href={terms.path()} class="text-primary underline text-sm"
            >Read the Terms of Service &rarr;</a
          >
        </section>
      </div>
    </div>
  </main>

  <MarketingFooter />
</div>
