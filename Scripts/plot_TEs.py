import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.cm import ScalarMappable
from matplotlib.ticker import MaxNLocator

def plot_data(df):
    df['length'] = df['length'] / 1e6
    # Remover linhas com valor zero
    df = df[df["Number"] != 0]

    # Use o tema 'seaborn-whitegrid' para uma estética melhorada
    #plt.style.use('seaborn-darkgrid')
    try:
        plt.style.use('seaborn-whitegrid')
    except OSError:
        plt.style.use('seaborn-v0_8-whitegrid')

    fig, ax1 = plt.subplots(figsize=(10, 6))

    # Cria uma escala de cor baseada na coluna "Number"
    colors = plt.cm.coolwarm(df['Number']/float(max(df['Number'])))

    # Bar plot
    bars = ax1.bar(df['Type'], df['Number'], color=colors)

    # Adicionar valores da coluna "Number" acima das barras
    for bar, number in zip(bars, df['Number']):
        ax1.text(bar.get_x() + bar.get_width() / 2, bar.get_height(), str(number), 
                 ha='center', va='bottom', color='black', fontsize=6)

    # Configuração do plot
    ax1.set_xlabel('TE Type', fontsize=12, color='black')
    ax1.set_ylabel("Number of elements", fontsize=12, color='black')
    ax1.set_title('Distribution of TEs: Number of elements', fontsize=14, color='black')
    ax1.grid(False)

    # Diminuir tamanho da fonte do eixo x e rotacionar
    plt.setp(ax1.get_xticklabels(), fontsize=6, color='black', rotation=35)

    # Inserir uma colorbar pequena no canto superior esquerdo
    axins = ax1.inset_axes([0.02, 0.8, 0.06, 0.1])
    sm = ScalarMappable(cmap='coolwarm', norm=plt.Normalize(min(df['Number']), max(df['Number'])))
    sm.set_array([])
    cbar = plt.colorbar(sm, cax=axins, orientation='vertical', shrink=0.5)
    cbar.ax.tick_params(labelsize=6)  # Reduz tamanho da fonte
    #cbar.set_ticks([min(df['Number']), df['Number'].mean(), max(df['Number'])])  # Apenas mínimo, médio e máximo
    cbar.set_ticks([min(df['Number']), max(df['Number'])])  # Apenas mínimo e máximo

    # Adicione o label "Occurrences" abaixo da colorbar
    ax1.annotate('Occurrences', xy=(0.093, 0.75), xycoords='figure fraction', fontsize=8, ha='left', color='black')

    plt.tight_layout()
    plt.savefig("TE-Report.pdf")

def main():
    df = pd.read_csv('plot1.txt', sep='\t')
    plot_data(df)

if __name__ == "__main__":
    main()

