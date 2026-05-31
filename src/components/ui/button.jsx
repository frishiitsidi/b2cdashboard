import React from "react";

export function Button({ className, variant, children, ...props }) {
  const baseStyle = "inline-flex items-center justify-center font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed text-sm rounded-full py-2.5 px-5";
  const variantStyle = variant === "secondary" 
    ? "bg-[#f5f5f7] hover:bg-neutral-200 text-[#1d1d1f]" 
    : "bg-black text-white hover:bg-black/90";
    
  return (
    <button className={`${baseStyle} ${variantStyle} ${className || ""}`} {...props}>
      {children}
    </button>
  );
}
