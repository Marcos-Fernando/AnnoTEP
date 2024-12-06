import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.cm import ScalarMappable
from matplotlib.ticker import MaxNLocator

def plot_data(df):
    # Remover linhas com valor zero
    df = df[df["Number"] != 0]

    # Use o tema 'seaborn-whitegrid' para uma estética melhorada
    #plt.style.use('seaborn-darkgrid')
    plt.style.use('seaborn-whitegrid')

    fig, ax1 = plt.subplots(figsize=(10, 6))

    # Cria uma escala de cor baseada na coluna "Number"
    colors = plt.cm.coolwarm(df['Number']/float(max(df['Number'])))

    # Bar plot
    bars = ax1.bar(df['Type'], df['length'], color=colors)

    # Adicionar valores da coluna "Number" acima das barras
    for bar, number in zip(bars, df['Number']):
        ax1.text(bar.get_x() + bar.get_width() / 2, bar.get_height(), str(number), 
                 ha='center', va='bottom', color='black', fontsize=6)

    # Criar segundo eixo Y
    ax2 = ax1.twinx()
    ax2.set_ylabel("Percentage of Genome Occupied", fontsize=12, color='black')
    ax2.set_yticks(df['percentage'])  # Volta para a versão anterior
    ax2.grid(False)  # Remove as linhas de grade do segundo eixo Y
    ax2.yaxis.set_major_locator(MaxNLocator(nbins=4))  # Limita para 6 ticks no eixo Y

    # Configuração do plot
    ax1.set_xlabel('TE Type', fontsize=12, color='black')
    ax1.set_ylabel("Length Occupied (Mb)", fontsize=12, color='black')
    ax1.set_title('TE-Report', fontsize=14, color='black')

    # Diminuir tamanho da fonte do eixo x e rotacionar
    plt.setp(ax1.get_xticklabels(), fontsize=6, color='black', rotation=35)

    # Inserir uma colorbar pequena no canto superior esquerdo
    #axins = ax1.inset_axes([0.02, 0.8, 0.06, 0.1])
    #sm = ScalarMappable(cmap='coolwarm', norm=plt.Normalize(min(df['Number']), max(df['Number'])))
    #sm.set_array([])
    #cbar = plt.colorbar(sm, cax=axins, orientation='vertical', shrink=0.5)

    # Inserir uma colorbar pequena no canto superior esquerdo
    axins = ax1.inset_axes([0.02, 0.8, 0.06, 0.1])
    sm = ScalarMappable(cmap='coolwarm', norm=plt.Normalize(min(df['Number']), max(df['Number'])))
    sm.set_array([])
    cbar = plt.colorbar(sm, cax=axins, orientation='vertical', shrink=0.5)
    cbar.ax.tick_params(labelsize=6)  # Reduz tamanho da fonte
    #cbar.set_ticks([min(df['Number']), df['Number'].mean(), max(df['Number'])])  # Apenas mínimo, médio e máximo
    cbar.set_ticks([min(df['Number']), max(df['Number'])])  # Apenas mínimo e máximo




    # Adicione o label "Occurrences" abaixo da colorbar
    ax1.annotate('Occurrences', xy=(0.075, 0.76), xycoords='figure fraction', fontsize=8, ha='left', color='black')

    plt.tight_layout()
    plt.savefig("TE-Report.pdf")

def main():
    df = pd.read_csv('plot1.txt', sep='\t')
    plot_data(df)

if __name__ == "__main__":
    main()