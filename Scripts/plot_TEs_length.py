import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.cm import ScalarMappable
from matplotlib.ticker import MaxNLocator


def plot_data(df):
    # Remover linhas com valor zero
    df['length'] = df['length'] / 1e6  # Converte bytes para megabases (Mb)

    df = df[df["length"] != 0]

    # Use o tema 'seaborn-whitegrid' para uma estética melhorada
    #plt.style.use('seaborn-darkgrid')
    try:
        plt.style.use('seaborn-whitegrid')
    except OSError:
        plt.style.use('seaborn-v0_8-whitegrid')

    fig, ax1 = plt.subplots(figsize=(10, 6))

    # Cria uma escala de cor baseada na coluna "length"
    colors = plt.cm.coolwarm(df['length']/float(max(df['length'])))

    # Bar plot
    bars = ax1.bar(df['Type'], df['length'], color=colors)

    # Adicionar valores da coluna "length" acima das barras
    for bar, length, perc in zip(bars, df['length'], df['percentage']):
        ax1.text(bar.get_x() + bar.get_width() / 2, bar.get_height(), 
            f'{length:.3f} Mb \n({perc:.2f}%)', ha='center', va='bottom', color='black', fontsize=6)


    # Criar segundo eixo Y
    ax2 = ax1.twinx()
    ax2.set_ylabel("Percentage of Genome Occupied", fontsize=12, color='black')
    ax2.set_yticks(df['percentage'])  # Volta para a versão anterior
    ax2.yaxis.set_major_locator(MaxNLocator(nbins=4))  # Limita para 6 ticks no eixo Y
    ax2.grid(False)  # Remove as linhas de grade do segundo eixo Y

    # Configuração do plot
    ax1.set_xlabel('TE Type', fontsize=12, color='black')
    ax1.set_ylabel("Length Occupied (Mb)", fontsize=12, color='black')
    ax1.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: f'{x:.1f}'))
    ax1.set_title('Distribution of TEs: Length and Occurrences', fontsize=14, color='black')
    ax1.grid(False)  # Remover grid do eixo principal

    # Diminuir tamanho da fonte do eixo x e rotacionar
    plt.setp(ax1.get_xticklabels(), fontsize=6, color='black', rotation=35)

    # Inserir uma colorbar pequena no canto superior esquerdo
    #axins = ax1.inset_axes([0.02, 0.8, 0.06, 0.1])
    #sm = ScalarMappable(cmap='coolwarm', norm=plt.Normalize(min(df['length']), max(df['length'])))
    #sm.set_array([])
    #cbar = plt.colorbar(sm, cax=axins, orientation='vertical', shrink=0.5)

    # Inserir uma colorbar pequena no canto superior esquerdo
    axins = ax1.inset_axes([0.02, 0.8, 0.06, 0.1])
    sm = ScalarMappable(cmap='coolwarm', norm=plt.Normalize(min(df['length']), max(df['length'])))
    sm.set_array([])
    cbar = plt.colorbar(sm, cax=axins, orientation='vertical', shrink=0.5)
    cbar.ax.tick_params(labelsize=6)  # Reduz tamanho da fonte
    #cbar.set_ticks([min(df['length']), df['length'].mean(), max(df['length'])])  # Apenas mínimo, médio e máximo
    cbar.set_ticks([min(df['length']), max(df['length'])])  # Apenas mínimo e máximo




    # Adicione o label "Occurrences" abaixo da colorbar
    ax1.annotate('Occurrences', xy=(0.075, 0.76), xycoords='figure fraction', fontsize=8, ha='left', color='black')

    plt.tight_layout()
    plt.savefig("TE-Report.pdf")

def main():
    df = pd.read_csv('plot1.txt', sep='\t')
    plot_data(df)

if __name__ == "__main__":
    main()
