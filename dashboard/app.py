import streamlit as st
st.title("🔥 Chaos Edge Dashboard")
st.metric("P99 Latency", "1,247ms", "↑18%")
st.metric("Error Rate", "12%", "↓3%")
st.line_chart({"Latency": [200, 450, 1247, 320, 189]})
if st.button("💥 Inject Chaos"): st.balloons()
