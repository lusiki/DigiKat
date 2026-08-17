# Visitor analytics on GitHub Pages

DigiKat currently does not add its own visitor-tracking script. GitHub Pages is static hosting, but
that does not prevent analytics. A privacy-conscious analytics service works by loading a small
JavaScript file in the generated HTML and recording an anonymous page view on the provider's server.

## Recommended setup

Use Plausible if the project decides that aggregate visitor counts justify an external processor.
Quarto supports Plausible directly, Plausible does not use cookies by default, and the provider states
that its standard setup does not require a cookie-consent banner. The account owner still needs to
check the university's privacy requirements and name the processor in the site's privacy note.

1. Create a Plausible account and add the DigiKat site.
2. Copy the complete, site-specific snippet from Plausible's **Site Installation** screen.
3. Add the snippet under `website: plausible-analytics` in `_quarto.yml`, exactly as Plausible provides
   it. Do not commit a placeholder identifier.
4. Render one page and confirm that the Plausible dashboard receives a test visit.
5. Update `pages/site-info.qmd` to name Plausible and link to the applicable privacy information.

The current Quarto instructions are maintained at
[Website Tools](https://quarto.org/docs/websites/website-tools.html#plausible-analytics).

## What GitHub Pages itself records

GitHub states that it logs a visitor's IP address for security when a GitHub Pages site is visited,
regardless of whether the visitor is signed in. That hosting-level logging exists even while DigiKat
has no project analytics. See
[What is GitHub Pages?](https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages#data-collection).
