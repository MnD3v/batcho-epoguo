"use client"
import { createContext, useContext, useState, ReactNode } from "react";

// Définit les types pour l'état et la fonction de mise à jour
interface GlobalStateContextType {
  menuIsOpen: boolean;
  setMenuIsOpen: (isOpen: boolean) => void;
}

// Crée le contexte avec un type par défaut (ou null initialement)
const GlobalStateContext = createContext<GlobalStateContextType | undefined>(undefined);

// Crée un hook pour utiliser le contexte
export const useGlobalState = () => {
  const context = useContext(GlobalStateContext);
  if (!context) {
    throw new Error("useGlobalState doit être utilisé dans un GlobalStateProvider");
  }
  return context;
};

// Définit les props du fournisseur
interface GlobalStateProviderProps {
  children: ReactNode;
}

// Composant fournisseur pour l'état global
export const GlobalStateProvider = ({ children }: GlobalStateProviderProps) => {
  const [menuIsOpen, setMenuIsOpen] = useState(false);

  return (
    <GlobalStateContext.Provider value={{ menuIsOpen, setMenuIsOpen }}>
      {children}
    </GlobalStateContext.Provider>
  );
};
