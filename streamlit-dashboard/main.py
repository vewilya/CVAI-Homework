import numpy as np
import pandas as pd
import plotly.express as px
import streamlit as st


def main():
    print("Hello from streamlit-dashboard!")

    st.title("CVAI Photogrammetrie-Evaluation")
    st.subheader(
        "Interaktive Auswertung der Rekonstruktionsqualität über Tools, Szenarien und Kameras"
    )
    st.caption("fabian stocker & urs bollhalder")

    st.sidebar.title("🔍 Filter")

    tools = st.sidebar.multiselect(
        "Werkzeuge",
        options=sorted(["Camera", "LiDAR"]),
        default=sorted(["Camera", "LiDAR"]),
    )

    app = st.sidebar.multiselect(
        "Applikation",
        options=sorted(
            [
                "COLMAP",
                "OpenMVG",
                "Meshroom",
                "Reality Composer",
                "Reality Capture",
                "Regard3D",
                "Zephyr Free",
            ]
        ),
        default=sorted(["Reality Composer"]),
    )

    surfaces = st.sidebar.multiselect(
        "Oberflächenbeschaffenheit",
        options=sorted(["matt", "reflektierend", "texturlos", "transparent"]),
        default=sorted(["texturlos"]),
    )

    complexity = st.sidebar.multiselect(
        "Komplexität",
        options=sorted(["einfach", "mittel", "komplex"]),
        default=sorted(["mittel"]),
    )

    st.markdown(
        """
        This is a playground for you to try Streamlit and have fun.

        **There's :rainbow[so much] you can build!**

        We prepared a few examples for you to get started. Just
        click on the buttons above and discover what you can do
        with Streamlit.
        """
    )

    if st.button("Send balloons!"):
        st.balloons()

    st.markdown("**Scatter-Plot**")

    np.random.seed(42)

    df_filt = pd.DataFrame(
        {
            "tool": np.random.choice(["colmap", "meshroom", "realitycapture"], 100),
            "scenario": np.random.choice(["A_ideal", "B_backlight", "C_lowlight"], 100),
            "camera_tier": np.random.choice(["webcam", "prosumer", "pro"], 100),
            "material": np.random.choice(["matt", "reflective", "textureless"], 100),
            "texture_score": np.random.uniform(0.2, 0.9, 100),
            "chamfer_mm": np.random.uniform(0.3, 5.0, 100),
            "f_score_1mm": np.random.uniform(0.3, 0.95, 100),
            "lux": np.random.uniform(50, 1200, 100),
            "n_images": np.random.choice([48, 96, 216], 100),
        }
    )
    numeric_cols = df_filt.select_dtypes("number").columns.tolist()
    cat_cols = ["tool", "scenario", "camera_tier", "material"]

    col1, col2, col3 = st.columns(3)
    x_col = col1.selectbox(
        "X-Achse", numeric_cols, index=numeric_cols.index("texture_score")
    )
    y_col = col2.selectbox(
        "Y-Achse", numeric_cols, index=numeric_cols.index("chamfer_mm")
    )
    color_col = col3.selectbox("Farbe", cat_cols)

    fig = px.scatter(df_filt, x=x_col, y=y_col, color=color_col, opacity=0.6)
    st.plotly_chart(fig, width="stretch")


if __name__ == "__main__":
    main()
