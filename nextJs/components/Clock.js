import { useEffect, useState } from "react"

export default function Clock() {
    const [currentTime, setCurrentTime] = useState("")

    useEffect(() => {
        const timer = setInterval(() => {
            updateTime()
        }, 1000)

        return () => {
            clearInterval(timer)
        }
    }, [])

    const updateTime = () => {
        const date = new Date()
        const hour = updateTimeFormat(date.getHours())
        const min = updateTimeFormat(date.getMinutes())
        const sec = updateTimeFormat(date.getSeconds())
        const year = date.getFullYear()
        const dayOfWeek = getDayOfWeek(date.getDay())

        setCurrentTime(`${hour} : ${min} :${sec} , ${dayOfWeek} , ${year}`)
    }

    const updateTimeFormat = (time) => {
        return time < 10 ? "0" + time : time
    }

    const getDayOfWeek = (index) => {
        const daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

        return daysOfWeek[index]
    }

    return (
        <div>
            <style jsx>{`
                * {
                    color: black;
                    user-select: none;
                    font-family: "Orbitron";
                }

                #clock {
                    font-size: 80px;
                    text-align: center;
                    padding-top: 50px;
                    padding-bottom: 40px;
                }

                h1 {
                    text-align: center;
                    padding-top: 0px;
                    font-size: 30px;
                }
            `}</style>

            <div id="clock" onClick={updateTime}>
                {currentTime}
            </div>

            <h1 className="font-orbitron">Welcome</h1>
        </div>
    )
}
