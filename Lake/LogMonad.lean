/-
Copyright (c) 2021 Mac Malone. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mac Malone
-/
import Lake.RealM

namespace Lake

-- # Typeclass

class MonadLog (m : Type u → Type v) where
  logInfo : String → m PUnit
  logWarning : String → m PUnit
  logError : String → m PUnit

export MonadLog (logInfo logWarning logError)

instance [MonadLift m n] [MonadLog m] : MonadLog n where
  logInfo msg := liftM (m := m) <| logInfo msg
  logWarning msg := liftM (m := m) <| logWarning msg
  logError msg := liftM (m := m) <| logError msg

-- # Context

structure LogMethods (m : Type u → Type v) where
  logInfo : String → m PUnit
  logWarning : String → m PUnit
  logError : String → m PUnit

namespace LogMethods

def nop [Pure m] : LogMethods m :=
  ⟨fun _ => pure (), fun _ => pure (), fun _ => pure ()⟩

instance [Pure m] : Inhabited (LogMethods m) := ⟨LogMethods.nop⟩

def io [MonadLiftT RealM m] : LogMethods m where
  logInfo msg := RealM.runIO_ <| IO.println msg
  logWarning msg := RealM.runIO_ <| IO.eprintln s!"warning: {msg}"
  logError msg := RealM.runIO_ <| IO.eprintln s!"error: {msg}"

def eio [MonadLiftT RealM m] : LogMethods m where
  logInfo msg := RealM.runIO_ <| IO.eprintln s!"info: {msg}"
  logWarning msg := RealM.runIO_ <| IO.eprintln s!"warning: {msg}"
  logError msg := RealM.runIO_ <| IO.eprintln s!"error: {msg}"

def lift [MonadLiftT m n] (self : LogMethods m) : LogMethods n where
  logInfo msg := liftM <| self.logInfo msg
  logWarning msg := liftM <| self.logWarning msg
  logError msg := liftM <| self.logError msg

end LogMethods

-- # Transformers

abbrev LogMethodsT (m : Type u → Type v) (n : Type v → Type w) :=
   ReaderT (LogMethods m) n

instance [Pure n] [Inhabited α] : Inhabited (LogMethodsT m n α) :=
  ⟨fun _ => pure Inhabited.default⟩

instance [Monad n] [MonadLiftT m n] : MonadLog (LogMethodsT m n) where
  logInfo msg := do (← read).logInfo msg
  logWarning msg := do (← read).logWarning msg
  logError msg := do (← read).logError msg

namespace LogMethodsT

abbrev run (methods : LogMethods m) (self : LogMethodsT m n α) : n α :=
  ReaderT.run self methods

abbrev runWith (methods : LogMethods m) (self : LogMethodsT m n α) : n α :=
  ReaderT.run self methods

abbrev adaptMethods [Monad n]
(f : LogMethods m → LogMethods m') (self : LogMethodsT m' n α) : LogMethodsT m n α :=
  ReaderT.adapt f self

end LogMethodsT

abbrev LogT (m : Type → Type) :=
  LogMethodsT m m

namespace LogT

def run (methods : LogMethods m) (self : LogT m α) : m α :=
  ReaderT.run self methods

def runWith (methods : LogMethods m) (self : LogT m α) : m α :=
  ReaderT.run self methods

end LogT