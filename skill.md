Spec produit (1 page) — FocusOne (1 micro-habitude)

1) Proposition de valeur

App iOS minimaliste qui suit une seule micro-habitude à la fois. L’utilisateur coche “Fait”, voit son streak et reçoit des rappels locaux. Quand l’habitude est stable, il peut la clôturer et passer à la suivante (Premium : historique complet + cycles).

⸻

2) Périmètre MVP
	•	1 habitude active en Free.
	•	Check-in en 1 tap (“Fait”).
	•	Streak + mini stats.
	•	Notifications locales.
	•	Sync iCloud (CloudKit).
	•	Widgets iOS (Lock Screen + Home) en version de base.

⸻

3) Écrans (MVP)

A. Onboarding (≤ 30 secondes)
Objectif : configurer l’habitude sans friction.
	•	Champs :
	•	Nom de l’habitude (ex: “10 min lecture”)
	•	Icône (emoji / SF Symbol)
	•	Couleur (thème)
	•	Fréquence : Quotidien (MVP, pas de x fois/semaine)
	•	Rappel : 0/1/2 heures (ex: 9:00, 21:00)
	•	“Journée commence à” (option avancée : par défaut 04:00)
	•	CTA : Démarrer

B. Home (écran principal)
Objectif : action immédiate + feedback.
	•	Éléments :
	•	Nom + icône + couleur
	•	Bouton Fait (état : fait / pas fait)
	•	Streak actuel (ex: “7 jours”)
	•	Prochain rappel (si actif)
	•	Mini feedback : “Aujourd’hui : ✔︎ / ✘”
	•	Actions :
	•	Tap “Fait” (toggle)
	•	Accès rapide Stats / Réglages

C. Stats
Objectif : visualiser sans complexité.
	•	Éléments :
	•	Calendrier mensuel (jours cochés)
	•	% complétion sur 7 / 30 jours
	•	Meilleur streak
	•	(Premium : historique complet + cycles, voir section 6)

D. Réglages
Objectif : contrôle minimal.
	•	Notifications : on/off, heures
	•	“Journée commence à” (04:00 par défaut)
	•	Thème (couleur)
	•	iCloud sync (status)
	•	Aide / feedback
	•	Premium (voir paywall)

E. Paywall (présenté quand nécessaire)
	•	Déclencheurs :
	•	Tentative de créer 2e habitude
	•	Accès historique/cycles/widgets avancés
	•	Message : “Plus d’habitudes, historique, widgets avancés”

⸻

4) Règles produit (streak, journée, validation)

4.1 Définition de “la journée”
	•	Une journée est une fenêtre [StartOfDay → StartOfDay+24h).
	•	Par défaut : StartOfDay = 04:00 (évite les cassures à minuit).
	•	L’utilisateur peut ajuster (Réglages).

4.2 Validation “Fait”
	•	Une complétion = au moins 1 check-in dans la journée.
	•	Toggle autorisé le même jour (annuler si erreur).

4.3 Calcul du streak (quotidien)
	•	Si “Fait” aujourd’hui :
	•	Si hier était “Fait” → streak = streak + 1
	•	Sinon → streak = 1
	•	Si “Pas fait” et la journée est terminée → streak revient à 0 (ou reste, selon affichage ; mais la série est cassée).
	•	Affichage : streak actuel + meilleur streak.

4.4 Notifications
	•	Locales uniquement.
	•	Rappels programmés aux heures choisies.
	•	Option MVP : pas de “smart reminders” conditionnels (Premium possible).

⸻

5) Données (conceptuel)
	•	Habit
	•	id, name, icon, color
	•	startDate
	•	dayStartHour (défaut 4)
	•	reminderTimes[]
	•	isActive
	•	Completion
	•	habitId
	•	dayKey (date normalisée selon dayStartHour)
	•	timestamp
	•	Cycle (Premium)
	•	habitId, cycleStart, cycleEnd, status (anchored/abandoned)

Stockage : Core Data + CloudKit (sync iCloud). Widgets lisent un snapshot simple (streak + doneToday).

⸻

6) Premium (4,99€/an — scope exact)

Free
	•	1 habitude active
	•	Streak + stats basiques (7/30 jours)
	•	Widgets basiques (1)
	•	Notifications (rappels simples)

Premium
	•	Habitudes illimitées (une active à la fois ou plusieurs actives : à décider ; recommandé : illimité mais 1 active pour rester cohérent)
	•	Historique complet (au-delà de 30 jours)
	•	Cycles : clôturer une habitude (“Ancrée”) + archives
	•	Widgets avancés (calendrier 7j, meilleur streak, stats semaine)
	•	Personnalisation extra (thèmes/couleurs supplémentaires)
	•	(Option future) “Joker” 1/mois + smart reminder

⸻

7) Critères de qualité (non négociables)
	•	Home utilisable en 1 seconde (ouvrir → taper → fermé).
	•	Aucune complexité de saisie (pas de quantités au MVP).
	•	Zéro backend.
	•	Animations légères, cohérentes, pas gadget.

⸻

8) Roadmap immédiate (post-MVP, si traction)
	1.	Fréquence “x fois/semaine”
	2.	Smart reminders + joker
	3.	Export CSV / PDF
	4.	Templates d’habitudes + onboarding plus rapide
