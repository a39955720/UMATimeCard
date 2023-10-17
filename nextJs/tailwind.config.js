/** @type {import('tailwindcss').Config} */
module.exports = {
    content: [],
    content: [
        "./app/**/*.{js,ts,jsx,tsx,mdx}",
        "./pages/**/*.{js,ts,jsx,tsx,mdx}",
        "./components/**/*.{js,ts,jsx,tsx,mdx}",
    ],
    theme: {
        extend: {
            fontFamily: {
                orbitron: ["Orbitron", "sans-serif"],
            },
        },
    },
    plugins: [],
}