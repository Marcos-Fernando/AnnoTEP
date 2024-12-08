import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.cm import ScalarMappable

def plot_data(df):

    df['length'] = df['length'] / 1e6
    
    # Remover linhas com valor zero e resetar índices
    df = df[df["Number"] != 0].reset_index(drop=True)

    # Use o tema 'seaborn-whitegrid' para uma estética melhorada
    try:
        plt.style.use('seaborn-whitegrid')
    except OSError:
        plt.style.use('seaborn-v0_8-whitegrid')

    fig, ax = plt.subplots(figsize=(10, 6))

    # Scatter plot
    bubbles = ax.scatter(df['Number'], df['length'], s=df['percentage']*100, 
                        c=df['percentage'], cmap='coolwarm', alpha=0.6)

    # Configuração do plot
    ax.set_xlabel('Occurrences', fontsize=12, color='black')
    ax.set_ylabel("Length Occupied (Mb)", fontsize=12, color='black')
    ax.set_title('TE-Report', fontsize=16, color='black')

    # Cria uma colorbar
    cbar = fig.colorbar(bubbles)
    cbar.set_label("Percentage of Genome Occupied", fontsize=8)
    cbar.ax.tick_params(labelsize=6)  # Reduz tamanho da fonte
    cbar.set_ticks([min(df['percentage']), df['percentage'].mean(), max(df['percentage'])])  # Apenas mínimo, médio e máximo

    # Adiciona rótulos aos pontos
    for x, y, s in zip(df['Number'], df['length'], df['Type']):
        plt.text(x, y, s, ha='center', va='top', fontsize=8)

    plt.tight_layout()
    plt.savefig("TE-Report.pdf")

def main():
    df = pd.read_csv('plot1.txt', sep='\t')
    plot_data(df)

if __name__ == "__main__":
    main()
