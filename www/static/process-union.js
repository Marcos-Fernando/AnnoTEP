 
//Criando função para mostra a hora atual em constate atualização
function getCurrentDateFormatted() {
	const now = new Date();
	const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
	const month = months[now.getMonth()];
	const day = String(now.getDate()).padStart(2, "0");
	const year = now.getFullYear();
	const hours = String(now.getHours()).padStart(2, "0");
	const minutes = String(now.getMinutes()).padStart(2, "0");
	const seconds = String(now.getSeconds()).padStart(2, "0");
	
	return `${month} ${day}, ${year} ${hours}:${minutes}:${seconds}`;
}

// Função para atualizar 'current-date' com a data/hora atual formatada
function updateCurrentDate() {
	const currentDateElement = document.getElementById("current-date");
	if (currentDateElement) {
		const formattedDate = getCurrentDateFormatted();
		currentDateElement.textContent = `Submitted: ${formattedDate}`;
	}
}

// Função para atualizar 'last-date' com a data/hora atual formatada
function updateLastDate() {
	const lastDateElement = document.getElementById("last-date");
	if (lastDateElement) {
		const formattedDate = getCurrentDateFormatted();
		lastDateElement.textContent = `Last status change: ${formattedDate}`;
	}
}

// Atualize a data atual e ultima
updateCurrentDate();
updateLastDate();

setInterval(updateCurrentDate, 1000);
setInterval(updateLastDate, 1000); 

//animação dos três pontos do Loading...
function animateLoadingDots() {
    const loadingDotsElement = document.getElementById("loading-dots");
    if (loadingDotsElement) {
        let dots = 0;
        setInterval(() => {
            dots = (dots + 1) % 4;
            const dotsString = ".".repeat(dots);
            loadingDotsElement.textContent = `Loading${dotsString}`;
        }, 500); 
    }
}

animateLoadingDots();
