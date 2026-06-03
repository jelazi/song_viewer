# Project Instructions

## Commit Messages
- ALWAYS use conventional commits format: `<type>: <description>`
- Types: feat, fix, docs, refactor, test, chore, style, perf
- Write in English
- Be detailed and descriptive
- Use bullet points in commit messages for clarity and structure
- Never do commit and push at the same time, only if asked
- The first line should be a general summary of all changes, followed by bullet points for detailed changes
- Example:
  feat: add user authentication with JWT tokens
  - Implement JWT token handling
  - Add login form validation
  - Update user model
- Example:
  fix: resolve null pointer exception in SelectRoomBloc
  - Add null check in bloc initialization
  - Update error handling logic
- Example:
  refactor: improve repository method naming
  - Rename getData to fetchData
  - Update method signatures for consistency

## Flutter Best Practices
- Always use `const` constructors for widgets where possible to improve performance
- Separate UI logic from business logic using state management patterns like BLoC
- Use `Keys` for widgets that need to maintain state across rebuilds (e.g., in lists)
- Prefer `StatelessWidget` over `StatefulWidget` when state is not needed
- Handle asynchronous operations with `FutureBuilder` or `StreamBuilder` appropriately
- Use `MediaQuery` for responsive design instead of hard-coded sizes
- Avoid deep widget trees; use composition and extract widgets into separate classes
- Follow naming conventions: PascalCase for classes, camelCase for variables and methods
- Use `debugPrint` instead of `print` for logging in production code
- Optimize images and assets; use appropriate formats and sizes

## BLoC Patterns
- When creating a BLoC, always separate into 3 parts: state, bloc, and event (use separate files or classes for clarity)
- Use immutable state classes with `Equatable` for proper state comparison
- Define events as classes extending `BlocEvent` or similar, with clear naming (e.g., `LoadDataEvent`)
- Keep business logic in the BLoC; avoid putting logic in UI widgets
- Use `BlocBuilder` for rebuilding UI based on state changes
- Use `BlocListener` for side effects like navigation or showing dialogs
- Handle errors gracefully in states (e.g., `ErrorState` with error message)
- Avoid direct access to BLoC from widgets; use `BlocProvider` and `context.read`
- Test BLoCs with `bloc_test` package, covering events, states, and edge cases
- Use `mapEventToState` or `on<Event>` methods for event handling
- When creating an event in BLoC, separate the event from the on event handler - example: on<SearchData>(_filterData); void _filterData(SearchData event, Emitter<ArchiveState> emit) {}
- Keep BLoCs focused on a single responsibility; split large BLoCs if needed

## Development Context Log
- A file `DEVLOG.md` in the project root serves as a persistent development context log
- **Before starting any task**, ALWAYS read `DEVLOG.md` first to understand the current state of the project — what has been done, what is in progress, what issues exist, and how things were implemented
- **After completing any task**, ALWAYS update `DEVLOG.md` with:
  - What was done (brief summary of changes)
  - What was fixed (any bugs or errors resolved, and how)
  - What is the current state (what works, what doesn't)
  - What is pending / next steps
  - Any known issues or technical debt
- Keep the log structured with dated entries (newest first) so it's easy to scan
- This ensures continuity between sessions — even if context is lost, the log provides full awareness of project state
- Never delete old entries; append new ones at the top
- Write the log in English for consistency
