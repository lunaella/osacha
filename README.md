<div align="center">

# お茶 · Osacha

**Matcha from Osaka.**

</div>

---

In Osaka they say *kuidaore* — eat until you drop. It is a city that takes
its pleasures seriously, and takes its time over them.

Osacha borrows that patience. Stone-ground tea, whisked slow, poured cold over
ice. A cup that asks you to sit down for a moment before the day picks up again.

This app is the counter you order it from.

---

## About

Osacha is an iOS ordering app for a matcha café — a small, focused storefront
for a menu that is deliberately narrow and deliberately good. Fourteen drinks,
seven desserts, each one photographed and priced the way it is actually sold:
by size, by the milk you choose, by whether you want ice cream with it.

Built with SwiftUI for iPhone.

## Purpose

Ordering matcha should feel like the drink itself — unhurried, uncluttered,
and honest about what you are paying for.

Most café apps bury the menu behind an account wall and hide the real price
until checkout. Osacha does the opposite. You can browse the entire menu before
you sign in, and every upgrade — a Grande pour, oat instead of dairy, a scoop
alongside the brownie — shows its cost on the button before you tap it.

Signing in is asked for once, at the moment it actually matters: when you order.

## Who it's for

- **Matcha drinkers** who know the difference between usucha and a latte, and
  want to choose their grind, size and milk rather than accept a default.
- **Regulars** who reorder the same Cheese Cloud Matcha every week and want it
  in three taps, with their address and payment already waiting.
- **First-timers** who want to read what is actually in a drink — and see the
  price — before committing to anything.

## Features

**Browsing**
- Full catalogue of 14 matcha drinks and 7 matcha desserts, with photography
- Search across the entire menu
- Favourites, saved per item
- Browse everything as a guest — no account needed to look

**Ordering**
- Per-size pricing (Regular / Grande / Venti) with the upgrade shown on each option
- Alternative milks — oat, soy, almond — priced transparently against regular
- Ice cream add-on where the dessert supports it
- Quantity, cart, and a running total that reflects every choice
- Order confirmation with a reference, total paid and pickup time

**Account**
- Mobile number sign-in with a one-time code — no passwords
- Editable profile: name, number, delivery address
- Multiple saved addresses, labelled Home / Work / Other
- Payment methods you can add and remove
- Order history and notifications

**Settings**
- Appearance: System, Light or Dark
- Language preference
- Privacy controls for location, tracking, offers and analytics
- Help & Support with an FAQ

## Built with

- **SwiftUI** — declarative UI throughout
- **iOS 16+**, iPhone
- **XcodeGen** — the project is generated from `project.yml`
- `UserDefaults` for cart, favourites and account persistence

## Running it

```bash
xcodegen generate
open Osacha.xcodeproj
```

Then build and run on any iPhone simulator.

If you don't have XcodeGen, `Osacha.xcodeproj` is committed — open it directly.

## Structure

```
Osacha/
├── Models/          Menu catalogue, cart entries, account data
├── Controllers/     Order state, session and persistence
└── Views/
    ├── Auth/        Splash, login, verification
    ├── Account/     Profile, addresses, payments, settings
    └── ...          Home, menu, product detail, cart
```

---

<div align="center">

*一期一会 — one time, one meeting.*
Every cup, only once.

</div>
