import Head from "next/head"
import Header from "../components/Header"
import Dashboard from "../components/Dashboard"

export default function Home() {
    return (
        <div>
            <Head>
                <title>UMA Time Card</title>
                <meta name="description" content="A UMA Time Card project" />
            </Head>
            <Header />
            <Dashboard />
        </div>
    )
}
