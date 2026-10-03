// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useEffect, useRef } from 'react'
import * as echarts from 'echarts'
import type { EChartsOption } from 'echarts'

/** ~40 行的 ECharts 封装：init / setOption / resize / dispose，不引第三方 wrapper */
export default function Chart({ option, height = 300 }: { option: EChartsOption; height?: number }) {
  const el = useRef<HTMLDivElement>(null)
  const chart = useRef<echarts.ECharts | null>(null)

  useEffect(() => {
    if (!el.current) return
    chart.current = echarts.init(el.current)
    const onResize = () => chart.current?.resize()
    window.addEventListener('resize', onResize)
    return () => {
      window.removeEventListener('resize', onResize)
      chart.current?.dispose()
      chart.current = null
    }
  }, [])

  useEffect(() => {
    chart.current?.setOption(option, true)
  }, [option])

  return <div ref={el} style={{ height, width: '100%' }} />
}
