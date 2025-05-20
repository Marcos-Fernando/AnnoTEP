#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.cm import ScalarMappable

def plot_data(df):
    # Remover linhas com valor zero e resetar índices
    df = df[df["Number"] != 0].reset_index(drop=True)

    # Estilo seguro
    if 'seaborn-v0_8-whitegrid' in plt.style.available:
        plt.style.use('seaborn-v0_8-whitegrid')
    elif 'seaborn-whitegrid' in plt.style.available:
        plt.style.use('seaborn-whitegrid')
    else:
        plt.style.use('default')

    # Criar figura com 4 colunas: painel 1 | colorbar 1 | painel 2 | colorbar 2
    fig, axs = plt.subplots(1, 4, figsize=(18, 7), gridspec_kw={"width_ratios": [1, 0.05, 1, 0.05]})

    bubble_size_factor = 100
    alpha_value = 0.5

    # Painel 1: visão geral
    ax1 = axs[0]
    norm1 = plt.Normalize(vmin=min(df['percentage']), vmax=max(df['percentage']))
    bubbles1 = ax1.scatter(
        df['Number'],
        df['length'],
        s=df['percentage'] * bubble_size_factor,
        c=df['percentage'],
        cmap='coolwarm',
        norm=norm1,
        alpha=alpha_value,
        edgecolors='w',
        linewidths=0.5
    )
    ax1.set_xlabel('Occurrences', fontsize=10, color='black')
    ax1.set_ylabel('Length Occupied (Mb)', fontsize=10, color='black')
    ax1.set_title('All TEs', fontsize=12, color='black')
    plt.setp(ax1.get_xticklabels(), fontsize=8, color='black')
    plt.setp(ax1.get_yticklabels(), fontsize=8, color='black')

    # Painel 2: zoom automático baseado nos 35% menores
    q45 = df['Number'].quantile(0.45)
    df_zoom = df[df['Number'] <= q45]

    ax2 = axs[2]
    norm2 = plt.Normalize(vmin=min(df_zoom['percentage']), vmax=max(df_zoom['percentage']))
    bubbles2 = ax2.scatter(
        df_zoom['Number'],
        df_zoom['length'],
        s=df_zoom['percentage'] * (bubble_size_factor * 6),
        c=df_zoom['percentage'],
        cmap='coolwarm',
        norm=norm2,
        alpha=alpha_value,
        edgecolors='w',
        linewidths=0.5
    )
    ax2.set_xlabel('Occurrences', fontsize=10, color='black')
    ax2.set_ylabel('Length Occupied (Mb)', fontsize=10, color='black')
    ax2.set_title(f'Zoom (Occurrences ≤ {q45:.1f})', fontsize=12, color='black')
    plt.setp(ax2.get_xticklabels(), fontsize=8, color='black')
    plt.setp(ax2.get_yticklabels(), fontsize=8, color='black')

    # Colorbars separadas
    cax1 = axs[1]
    sm1 = ScalarMappable(cmap='coolwarm', norm=norm1)
    sm1.set_array([])
    cbar1 = plt.colorbar(sm1, cax=cax1)
    cbar1.set_label("All TEs (%)", fontsize=8, color='black')
    cbar1.ax.tick_params(labelsize=6)

    cax2 = axs[3]
    sm2 = ScalarMappable(cmap='coolwarm', norm=norm2)
    sm2.set_array([])
    cbar2 = plt.colorbar(sm2, cax=cax2)
    cbar2.set_label("Zoomed TEs (%)", fontsize=8, color='black')
    cbar2.ax.tick_params(labelsize=6)

    # Adicionar rótulos de pontos
    for x, y, label in zip(df['Number'], df['length'], df['Type']):
        if x > 0 and y > 0:
            ax1.annotate(
                label,
                (x, y),
                textcoords="offset points",
                xytext=(0, -5),
                ha='center',
                fontsize=9,
                color='black'
            )

    for x, y, label in zip(df_zoom['Number'], df_zoom['length'], df_zoom['Type']):
        if x > 0 and y > 0:
            ax2.annotate(
                label,
                (x, y),
                textcoords="offset points",
                xytext=(0, -5),
                ha='center',
                fontsize=9,
                color='black'
            )

    plt.tight_layout()

    #  Salvar
    plt.savefig("TE-Report2-bubble-panels.pdf", dpi=350)
    plt.savefig("TE-Report2-bubble-panels.png", dpi=350)
    plt.close()

def main():
    df = pd.read_csv('plot1.txt', sep='\t')
    plot_data(df)

if __name__ == "__main__":
    main()
