#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.cm import ScalarMappable

def plot_data(df):
    # Remover linhas com valor zero e resetar índices
    df = df[df["Number"] != 0].reset_index(drop=True)

    # Estilo: tentar usar seaborn-whitegrid de forma segura
    if 'seaborn-v0_8-whitegrid' in plt.style.available:
        plt.style.use('seaborn-v0_8-whitegrid')
    elif 'seaborn-whitegrid' in plt.style.available:
        plt.style.use('seaborn-whitegrid')
    else:
        plt.style.use('default')

    fig, ax = plt.subplots(figsize=(8, 6))

    # Scatter plot (bubbles)
    bubbles = ax.scatter(
        df['Number'], 
        df['length'], 
        s=df['percentage'] * 100, 
        c=df['percentage'], 
        cmap='coolwarm', 
        alpha=0.7, 
        edgecolors='w', 
        linewidths=0.5
    )

    # Configurações dos eixos
    ax.set_xlabel('Occurrences', fontsize=10, color='black')
    ax.set_ylabel('Length Occupied (Mb)', fontsize=10, color='black')
    ax.set_title('TE-Report', fontsize=12, color='black')

    plt.setp(ax.get_xticklabels(), fontsize=8, color='black')
    plt.setp(ax.get_yticklabels(), fontsize=8, color='black')

    # Criar colorbar pequena e harmonizada
    cbar = fig.colorbar(bubbles)
    cbar.set_label("Percentage of Genome Occupied", fontsize=8, color='black')
    cbar.ax.tick_params(labelsize=6)
    cbar.set_ticks([min(df['percentage']), max(df['percentage'])])

    # Adicionar rótulos aos pontos
    for x, y, label in zip(df['Number'], df['length'], df['Type']):
        ax.annotate(
            label, 
            (x, y), 
            textcoords="offset points", 
            xytext=(0, -5), 
            ha='center',
            fontsize=6,
            color='black'
        )

    plt.tight_layout()

    # Salvar em PDF e PNG
    plt.savefig("TE-Report-bubble.pdf", dpi=350)
    plt.savefig("TE-Report-bubble.png", dpi=350)
    plt.close()

def main():
    df = pd.read_csv('plot1.txt', sep='\t')
    plot_data(df)

if __name__ == "__main__":
    main()
