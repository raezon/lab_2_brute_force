document.getElementById('loginForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const username = document.getElementById('username').value.trim();
  const password = document.getElementById('password').value.trim();
  const message = document.getElementById('message');

  try {
    const resp = await fetch('users.json');
    const users = await resp.json();

    const user = users.find(u => u.username === username && u.password === password);
    if (user) {
      // Redirection vers la page bienvenue
      window.location.href = `welcome.html?user=${encodeURIComponent(user.username)}`;
    } else {
      message.textContent = 'Identifiants incorrects';
    }
  } catch (err) {
    console.error(err);
    message.textContent = 'Erreur lors du chargement des données';
  }
});
