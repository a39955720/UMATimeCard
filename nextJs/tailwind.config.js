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
            padding: {
                50: "16rem", // 添加一个名为 '30' 的 padding 值，对应 30 像素
            },
        },
    },
    plugins: [],
}
