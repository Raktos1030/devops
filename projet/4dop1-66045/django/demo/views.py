from django.shortcuts import render

# Cette classe joue le rôle de votre composant @Service ou @Component en Spring
class AppStats:
    def __init__(self):
        self.view_count = 0

    def increment(self):
        self.view_count += 1

# On instancie l'objet ici, au chargement du module. 
# C'est notre Singleton.
counter = AppStats()

def index(request):
    # On utilise l'instance unique
    counter.increment()

    context = {
        'view_count': counter.view_count,
        'version': 'B (Django)'
    }
    return render(request, 'index.html', context)
