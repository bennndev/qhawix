# Lovable landing integration

The master specification assigns the landing page to a separate Lovable project/repository. This directory records the integration contract; it is not a second editable landing source.

The landing must describe only the shipped Flutter Android build, show Escudo QR's three states and limits, explain that Guardian reviews a real payment request but cannot block or execute a payment, provide FAQ/privacy/compatibility/install guidance, and keep download disabled until a real signed APK and verified release manifest exist. Provide a normal HTTPS link alongside any download QR for people using the same phone.

Required release data is defined by `../../contracts/release-manifest.schema.json`. Synchronize the landing's version, package ID, minimum Android API, ABI, APK URL, SHA-256, signing-certificate SHA-256, size, release date, and notes from the same reviewed release. Never publish provider secrets, case data, fake download links, invented testimonials, or unmeasured protection claims.

No Lovable project, external repository, domain, or public landing URL is connected in this checkout. Create/connect it only in the owner-approved Lovable account, then record the canonical repository and staging/production URLs here.
