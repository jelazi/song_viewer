# Songs Viewer BLoC - TODO Seznam refaktorizace

## 📋 Přehled

Tento dokument obsahuje seznam navrhovaných vylepšení pro refaktorizaci aplikace Songs Viewer BLoC. Seznam je seřazen podle priority.

---

## 🎯 Stav refaktorizace

### ✅ Dokončeno

#### 1. Refaktorovat globální závislosti
- **Stav:** ✅ DOKONČENO
- **Popis:** Přesunout globální proměnné do dependency injection
- **Implementace:**
  - Vytvořena `AppRepositories` třída pro zapouzdření všech závislostí
  - Odstraněny `late` globální proměnné
  - Závislosti se předávají přes konstruktory BLoC tříd
  - View komponenty používají BLoC state místo přímých globálních proměnných

---

## 🔥 Vysoká priorita

#### 2. Implementovat comprehensive error handling
- **Stav:** ⏳ Připraven k implementaci
- **Popis:** Vytvořit robustní systém pro zpracování chyb
- **Implementace:**
  - Vytvořit custom Exception třídy (`NetworkException`, `DataException`, `ValidationException`)
  - Přidat retry mechanismy pro síťové operace
  - Implementovat centralizovaný error handler
  - Nahradit `logger.e('$e')` za user-friendly error messages
  - Přidat error recovery mechanismy

#### 3. Implementovat security measures
- **Stav:** ⏳ Připraven k implementaci
- **Popis:** Zabezpečit citlivé údaje a konfigurace
- **Implementace:**
  - Přesunout hardcoded API token (`tokenPisnickyAkordy`) z WebProvider do environment variables
  - Implementovat configuration management pomocí `flutter_dotenv`
  - Použít Flutter secure storage pro citlivé údaje
  - Přidat validation pro API keys

#### 4. Rozdělit velké BLoC třídy
- **Stav:** ⏳ Připraven k implementaci
- **Popis:** Refaktorovat komplexní BLoC třídy na menší, specifické komponenty
- **Implementace:**
  - Rozdělit `WebBloc` na `WebSearchBloc`, `WebContentBloc`, `WebHistoryBloc`
  - Rozdělit `HomePageBloc` na `SongListBloc`, `FilterBloc`, `GroupsBloc`
  - Implementovat Cubit pro jednodušší state management
  - Použít kompozici místo dědičnosti

---

## ⚡ Střední priorita

#### 5. Standardizovat error handling pattern
- **Stav:** ⏳ Čeká na implementaci
- **Popis:** Nahradit všechny `catch (e) { logger.e('$e'); return false; }` bloky
- **Implementace:**
  - Strukturovaný error handling s recovery mechanismy
  - Proper exception types
  - Consistent error reporting

#### 6. Implementovat BLoC testy
- **Stav:** ⏳ Čeká na implementaci
- **Popis:** Vytvořit comprehensive test suite pro BLoC layer
- **Implementace:**
  - BLoC testy pro všechny BLoC třídy (aktuálně chybí úplně)
  - Integration testy pro kritické user flows
  - Mock repositories pro izolované testování

#### 7. Optimalizovat responsivní design
- **Stav:** ⏳ Čeká na implementaci
- **Popis:** Eliminovat duplicitní kód napříč platformami
- **Implementace:**
  - Společné komponenty s responsivními vlastnostmi
  - Design system s reusable widgets
  - Konzistentní `LayoutBuilder` a `MediaQuery` použití

#### 8. Zlepšit testovatelnost
- **Stav:** ⏳ Čeká na implementaci
- **Popis:** Refaktorovat třídy pro lepší dependency injection
- **Implementace:**
  - WebProvider dependency injection (Dio)
  - Mockable providers
  - Interface abstractions

---

## 🔧 Nízká priorita

#### 9. Implementovat state management s freezed
- **Stav:** ⏳ Čeká na implementaci
- **Popis:** Immutable state objekty s freezed package
- **Implementace:**
  - Freezed annotations pro BLoC states
  - Sealed classes pro různé state stavy
  - Rozdělit složité stavy na menší komponenty

#### 10. Optimalizovat data synchronizaci
- **Stav:** ⏳ Čeká na implementaci
- **Popis:** Zlepšit Firebase/Hive synchronizaci
- **Implementace:**
  - Single source of truth pattern
  - Conflict resolution strategies
  - Offline-first architecture

#### 11. Standardizovat code style
- **Stav:** ⏳ Čeká na implementaci
- **Popis:** Konzistentní formátování a dokumentace
- **Implementace:**
  - Dart format a lint rules
  - Standardizovat jazyk dokumentace (nyní mix čeština/angličtina)
  - Pre-commit hooks

#### 12. Implementovat memory management
- **Stav:** ⏳ Čeká na implementaci
- **Popis:** Opravit potential memory leaks
- **Implementace:**
  - Proper disposal v BLoC dispose methods
  - StreamSubscription management
  - Memory monitoring

#### 13. Performance optimalizace
- **Stav:** ⏳ Čeká na implementaci
- **Popis:** Optimalizovat výkon aplikace
- **Implementace:**
  - Background processing pro těžké operace
  - Isolates pro CPU-intensive tasks
  - Loading states a progressive loading

#### 14. Zlepšit logging systém
- **Stav:** ⏳ Čeká na implementaci
- **Popis:** Strukturovaný logging systém
- **Implementace:**
  - Standardizovat formát log zpráv
  - Structured logging
  - Logging middleware pro BLoC eventy
  - Konzistentní úrovně detailu

---

## 📊 Statistiky

- **Celkem úkolů:** 14
- **Dokončeno:** 1 (7%)
- **Vysoká priorita:** 3 (21%)
- **Střední priorita:** 4 (29%)
- **Nízká priorita:** 6 (43%)

---

## 📝 Poznámky

- Tento dokument je živý - aktualizuje se podle postupu refaktorizace
- Před začátkem každého úkolu zkontrolovat aktuální stav kódu
- Testování by mělo probíhat průběžně během implementace
- Změny dokumentovat v tomto souboru

---

*Poslední aktualizace: 7. listopadu 2025*