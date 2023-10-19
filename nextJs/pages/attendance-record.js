import Head from "next/head"
import Header from "../components/Header"
import AttendanceRecord from "../components/AttendanceRecord"

export default function Home() {
    return (
        <div className="bg-yellow-400 flex-col min-h-screen">
            <Head>
                <title>UMA Time Card</title>
                <meta name="description" content="Display attendance record" />
            </Head>
            <Header />
            <AttendanceRecord />
        </div>
    )
}
