# Bora — contexto de arquitetura

App iOS de corrida guiada por áudio.

## Arquitetura

- **MVVM + Coordinator**. ViewModel é `@Observable final class`, view segura via `@State private var viewModel = ...`.
- `AppCoordinator` (`Bora/Core/Navigation/AppCoordinator.swift`) é o único dono de `NavigationPath`/navegação. ViewModel recebe closure de navegação (`onNext`, `onDone`, etc) via `init` — não referencia `AppCoordinator` nem constrói `AppRoute` diretamente.
- Novo fluxo de tela = novo caso em `AppRoute` + branch no `switch` de `RootCoordinatorView`.

## Dependency Injection

- Manual: protocolo + injeção via `init`. Sem lib terceira (Factory e swift-dependencies foram avaliados e descartados — overhead de curva de aprendizado/dependência externa não compensa pro escopo solo/MVP).
- `@Environment(\.appDependencies)` é a única exceção, só para acesso cross-cutting a `AppDependencies` sem precisar de init-injection em toda view intermediária.
- Composition root é `AppDependencies` (`Bora/Core/DI/AppDependencies.swift`) — novo serviço entra ali com um par protocolo+implementação em `Bora/Core/Services/`.

## Módulos

- Target único, pastas por feature (`Bora/Features/<Feature>/`). Não usar Swift Package local — decisão explícita, não propor modularização por SPM sem pedido.

## Plataforma

- iPhone only. Não reintroduzir iPad/macOS/visionOS sem decisão explícita — foram removidos de `TARGETED_DEVICE_FAMILY`/`SUPPORTED_PLATFORMS` no `project.pbxproj` porque o app depende de GPS em campo/tela bloqueada, cenário que não faz sentido nas outras plataformas.

## Escopo do MVP

Fora do MVP por decisão explícita: persistência entre sessões, conta de usuário, nuvem/Firebase, templates reutilizáveis, HealthKit, Strava, progressão automática, smartwatch. Isso é direção futura — o modelo de dados deve deixar espaço pra extensão (ex: campos opcionais em métricas de sessão para HR/cadência real), mas não implementar essas features agora nem adicionar abstração especulativa pra elas.

Sem identidade visual ainda — só componentes/cores padrão do sistema iOS/SwiftUI.

## Teste

Swift Testing (`@Test`, `#expect`), não XCTest, para lógica nova. `BoraUITests` fica em XCTest (gerado pelo template, fora de escopo mudar).

## Lint

SwiftLint, config em `.swiftlint.yml`, gate obrigatório no CI (`.github/workflows/lint.yml`) antes de merge em `main`. Corrigir violação real no código — não silenciar ajustando a config, a menos que a regra não se aplique ao caso (ex: override de API do sistema).
