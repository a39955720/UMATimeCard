import Head from "next/head"
import Image from "next/image"
import Header from "../components/Header"
import Clock from "../components/Clock"

export default function Home() {
    return (
        <div>
            <Head>
                <title>UMA Time Card</title>
                <meta name="description" content="A UMA Time Card project" />
                <link rel="icon" href="/logo1.png" />
            </Head>
            <Header />
            <Clock />
        </div>
    )
}
