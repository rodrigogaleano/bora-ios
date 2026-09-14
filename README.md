# Bora

App iOS nativo (SwiftUI) de corrida guiada por áudio. Você planeja a sessão (metas, blocos, sons) e o app guia por voz/beep/metrônomo durante a corrida, com a tela bloqueada.

## Requisitos

- Xcode 26.6+
- iOS 26.5+ (deployment target do projeto)
- iPhone apenas (iPad/macOS/visionOS fora de escopo)

## Rodando

```bash
open Bora.xcodeproj
```

Ou via linha de comando:

```bash
xcodebuild build -project Bora.xcodeproj -scheme Bora \
  -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug

xcodebuild test -project Bora.xcodeproj -scheme Bora \
  -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:BoraTests
```

## Arquitetura

- **MVVM + Coordinator** — `@Observable` ViewModel por tela, `AppCoordinator` dirige a `NavigationStack`. ViewModel recebe closure de navegação via `init`, não conhece o grafo de rotas.
- **DI manual** — protocolo + injeção via `init`, sem lib terceira. `@Environment` só para `AppDependencies` (caso cross-cutting).
- **Módulos** — target único, pastas por feature (`Bora/Features/*`).
- **Teste** — Swift Testing (`@Test`), não XCTest.

Detalhes e decisões registradas em [CLAUDE.md](CLAUDE.md).

## Lint

SwiftLint roda no CI (`.github/workflows/lint.yml`) em todo PR para `main`. Rodar localmente:

```bash
brew install swiftlint
swiftlint lint --strict
```
