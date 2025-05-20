#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.cm import ScalarMappable
from matplotlib.ticker import MaxNLocator

def plot_data(df):
    # Remover linhas com valor zero
    df = df[df["Number"] != 0]

    # Estilo: tentar usar seaborn-whitegrid
    if 'seaborn-v0_8-whitegrid' in plt.style.available:
        plt.style.use('seaborn-v0_8-whitegrid')
    elif 'seaborn-whitegrid' in plt.style.available:
        plt.style.use('seaborn-whitegrid')
    else:
        plt.style.use('default')

    fig, ax1 = plt.subplots(figsize=(8, 6))

    # Criar escala de cores baseada em "Number"
    colors = plt.cm.coolwarm(df['Number'] / float(max(df['Number'])))

    # Bar plot
    bars = ax1.bar(df['Type'], df['length'], color=colors)

    # Adicionar valores da coluna "Number" acima das barras
    for bar, number in zip(bars, df['Number']):
        ax1.text(
            bar.get_x() + bar.get_width() / 2, 
            bar.get_height(), 
            str(number),
            ha='center', va='bottom', 
            color='black', fontsize=6
        )

    # Segundo eixo Y (Percentage)
    ax2 = ax1.twinx()
    ax2.set_ylabel("Percentage of Genome Occupied", fontsize=10, color='black')
    ax2.set_yticks(df['percentage'])
    ax2.grid(False)
    ax2.yaxis.set_major_locator(MaxNLocator(nbins=4))

    # Configurações gerais
    ax1.set_xlabel('TE Type', fontsize=10, color='black')
    ax1.set_ylabel("Length Occupied (Mb)", fontsize=10, color='black')
    ax1.set_title('TE-Report', fontsize=12, color='black')

    plt.setp(ax1.get_xticklabels(), fontsize=6, color='black', rotation=35)

    # Inserir colorbar pequena
    axins = ax1.inset_axes([0.02, 0.8, 0.06, 0.1])
    sm = ScalarMappable(cmap='coolwarm', norm=plt.Normalize(min(df['Number']), max(df['Number'])))
    sm.set_array([])
    cbar = plt.colorbar(sm, cax=axins, orientation='vertical')
    cbar.ax.tick_params(labelsize=6)
    cbar.set_ticks([min(df['Number']), max(df['Number'])])

    # Adicionar rótulo "Occurrences" para a colorbar
    ax1.annotate('Occurrences', xy=(0.075, 0.76), xycoords='figure fraction', fontsize=6, ha='left', color='black')

    plt.tight_layout()

    # Salvar em PDF e PNG
    plt.savefig("TE-Report2-bar.pdf", dpi=350)
    plt.savefig("TE-Report2-bar.png", dpi=350)
    plt.close()

def main():
    df = pd.read_csv('plot1.txt', sep='\t')
    plot_data(df)

if __name__ == "__main__":
    main()
