import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.cm import ScalarMappable

def plot_data(df):
    # Converter 'length' para megabases (Mb)
    df['length'] = df['length'] / 1e6  # De bytes para Mb

    # Remover linhas com valores zero
    df = df[df["length"] != 0]

    # Ordenar do maior para o menor comprimento (length)
    df = df.sort_values(by="length", ascending=False)

    # Configurar estilo
    plt.style.use('seaborn-whitegrid')

    fig, ax = plt.subplots(figsize=(10, 6))

    # Criar cores baseadas no comprimento
    colors = plt.cm.coolwarm(df['length'] / max(df['length']))

    # Gráfico de barras horizontal
    bars = ax.barh(df['Type'], df['length'], color=colors)

    # Adicionar valores nas barras
    for bar, length, perc in zip(bars, df['length'], df['percentage']):
        ax.text(bar.get_width() + 0.1, bar.get_y() + bar.get_height() / 2, 
                f'{length} bp ({perc:.2f}%)', va='center', ha='left', fontsize=8, color='black')
                # f'{length} bp  {length:.2f} Mb  ({perc:.2f}%)', va='center', ha='left', fontsize=8, color='black')

    # Configurações do eixo X e título
    ax.set_xlabel("Length Occupied (Mb)", fontsize=12, color='black')
    ax.set_ylabel("TE Type", fontsize=12, color='black')
    ax.set_title("Distribution of TEs: Length and Percentage", fontsize=14, color='black')
    ax.grid(axis='x', linestyle='--', alpha=0.7)  # Grade no eixo X
    ax.grid(False)
    ax.invert_yaxis()

    # Adicionar uma colorbar ao lado direito
    sm = ScalarMappable(cmap='coolwarm', norm=plt.Normalize(min(df['length']), max(df['length'])))
    sm.set_array([])
    cbar = plt.colorbar(sm, ax=ax, orientation='vertical', shrink=0.5)
    cbar.set_ticks([min(df['length']), max(df['length'])])
    cbar.set_label('Occurrences', fontsize=10)
    cbar.ax.tick_params(labelsize=8)

    plt.tight_layout()
    plt.savefig("TE-Report.pdf")

def main():
    # Ler os dados
    df = pd.read_csv('plot1.txt', sep='\t')
    plot_data(df)

if __name__ == "__main__":
    main()
