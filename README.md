# Hands-on: Creating a Survival Game in Roblox

Project developed during the "Game Developer Training: Roblox & Metaverse" bootcamp, under the guidance of expert [Leonardo Vasques](https://www.linkedin.com/in/leonardovasques/ "Leonardo Vasques").
This repository contains the core scripts and configuration to run a simple zombie survival experience: player movement and aiming, shooting, server‑authoritative projectiles, zombie spawning and scoring. A compact, cross‑tech demo that started as a responsive HTML/CSS/JavaScript prototype and was ported to Roblox using Lua.

## Technologies used

- **HTML**: Provides the semantic structure for the web prototype: header, main, canvas, HUD and controls. This structure was used to validate UI/UX, accessibility and responsive behavior before porting gameplay ideas to Roblox.

- **CSS**: Implements the visual system: dark/light themes, color tokens, focus outlines and responsive layout. CSS allowed quick iteration on visual hierarchy and accessibility (contrast, readable fonts, focus states).  

- **JavaScript**: Runs the browser prototype: canvas rendering loop, entity management (player, bullets, zombies, particles), input handling (keyboard, mouse, touch), multilingual strings, persistent theme/language via `localStorage`, and WebAudio for procedural sound effects. The prototype served as a functional spec for gameplay and tuning.  

- **Lua (Roblox)**: Implements the multiplayer, authoritative version: `Config` centralizes tuning; `ZombieSpawner` runs on the server to spawn and move zombies, create projectiles and award points; `PlayerController` runs on the client to capture input and request actions. Server authority prevents client cheating and enables consistent multiplayer behavior.  

- **AI (assistive)**: Used during development to generate example code, tune parameters, create SVG sprite examples and propose UX improvements.

## Quick features summary

- **Playable prototype (browser)**: responsive canvas game with dark/light theme, multilingual UI (EN/PT-BR/ES), touch controls and WebAudio effects.
- **Roblox implementation**: server‑side zombie spawner, server‑authoritative projectiles, client input and HUD, leaderstats for scoring.
- **Accessibility**: semantic HTML, `aria-live` updates, keyboard controls and visible focus styles in the web prototype.
- **Tuning**: central `Config` module (Lua) and constants in JS for easy difficulty adjustments.
- **Assets**: sprite examples provided as SVGs; recommended 48×48 PNG sprite sheets for in‑game decals or billboard GUIs.

## Setup and quick start

1. Open **Roblox Studio**.  
2. Create `ReplicatedStorage/Config` ModuleScript and paste `config.lua`.  
3. Create `ReplicatedStorage/RemoteEvents` folder and add `FireBullet` RemoteEvent.  
4. Add `ZombieSpawner` script to `ServerScriptService` and paste `ZombieSpawner.lua`.  
5. Add `PlayerController` LocalScript to `StarterPlayerScripts` and paste `PlayerController.lua`.  
6. Press **Play** in Studio to test. Use mouse click or spacebar to shoot.

## Tuning and customization tips

- **Adjust difficulty**: change `Config.Zombie.SpawnInterval`, `BaseSpeedMin`, `BaseSpeedMax`, and `SpeedPerScore`.  
- **Projectile behavior**: tweak `Config.Projectile.Speed` and `Damage`. Consider switching to server raycasts for instant‑hit weapons.  
- **Visuals**: replace simple Parts with meshes, animated rigs or BillboardGuis using 48×48 sprites for a retro look.  
- **Audio**: attach `Sound` instances on the server for global effects or use client WebAudio for local effects. Persist volume and mute settings in `PlayerGui` or `Player` attributes.  
- **Navigation**: use `PathfindingService` for smarter zombie movement around obstacles.

![Screenshot](./docs/assets/game.png)

[LICENSE](./LICENSE)
