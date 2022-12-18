-- x gérer le "passage" de la balle sur le côté de la raquette
-- x faire des briques de type différent (plus ou moins solides, indestructibles)
-- x faire un système de score
-- x faire un système de vies
-- x empêcher la raquette de sortir de moitié de l'écran
-- x gérer l'affichage si gagné ou perdu (centrer texte)
-- x intervertir ordre aléatoire/niveaux dans le menu
-- x Ajouter le nom du jeu sur menu et indiquer "faitre vore choix" plutot que menu
-- x faire un système de niveau (différents niveaux)
-- x faire un système de bonus/malus (vitesse balle, vitesse pad, largeur pad...)
-- x rajouter du son
-- o gérer la "pénétration" par le côté sur les briques
-- x colorer la brique de victoire en jaune
-- x vérifier l'affichage de l'écran de victoire ou défaite (affichage du score, relancer la partie)
-- x fignoler la sélection du menu (afficher un sélecteur, changer le couleur du choix sélectionné
-- x indiquer sur le menu comment sélectionner (espace + entrée)
-- o internationaliser le code (anglais, etc.)
--
-- BUGS
-- 
-- o la balle pénètre dans les briques parfois
-- o la balle démarre avec une vitesse très lente parfois
-- o la balle, après une victoire ou une défaite, conserve ses carac (longueur, vitesse balle, etc;) -> la réinitialiser après victoire ou défaite
-- o l'écran "you win" ou "you lose" ne s'affiche qu'une fraction de seconde

require 'levels'

--Empêche le filtrage des contours
love.graphics.setDefaultFilter('nearest')

local pad = {}
pad.x = 0
pad.y = 0
pad.largeur = 80
pad.hauteur = 20
pad.actif = true
pad.score = 0
pad.nbriques = 0
pad.niveau = 1

local balle = {}
balle.x = 0
balle.y = 0
balle.r = 10
balle.colle = false
balle.vx = 0
balle.vy = 0
balle.vconst = 280
balle.dirx = 1
balle.diry = -1
balle.angle = math.pi / 4

local brique = {}

local niveau = {}

local choixMenu = {"niveaux", "aleatoire", "aide", "quit"}
local menuSelec = 1
local selection = false
local ecran = 'menu'
local sonPad = love.audio.newSource("Sons/arkanoid_raquette.wav", "static")
local sonMur = love.audio.newSource("Sons/DM-CGS-07.wav", "static")
local sonBriqueCollision = love.audio.newSource("Sons/arkanoid_brique.wav", "static")
local sonBriqueDetruite = love.audio.newSource("Sons/brickCollision.wav", "static")
local sonBriqueDure = love.audio.newSource("Sons/arkanoid_brique_dure.wav", "static")
local sonMiss = love.audio.newSource("Sons/arkanoid_perdu.wav", "static")
local sonGameOver = love.audio.newSource("Sons/arkanoid_perdu2.wav", "static")
local sonDemarre = love.audio.newSource("Sons/arkanoid_music_start.wav", "static")
local sonBonus = love.audio.newSource("Sons/arkanoid_granderaquette.wav", "static")
local sonMalus = love.audio.newSource("Sons/destroy.wav", "static")
local sonMenu = love.audio.newSource("Sons/arkanoid_music_intro.wav", "static")


function Demarre()

  balle.colle = true
  balle.nombre = 3
  balle.vconst = 280
  balle.vx = 0
  balle.vy = 0

  pad.largeur = 80
  pad.score = 0
  pad.nbriques = 0
  pad.x = largeur/2 
  sonDemarre:play()

end


function CreationNiveau(pChoix)
  --pChoix = "aleatoire" -- pour le dév du jeu avant que le système de niveau soit créé
  if pChoix == "aleatoire" then
    
    -- création d'un niveau aléatoire, on crée d'abord une surface 6x16 de briques de base
    niveau = {}
    local l, c
    for l = 1, 6 do
      niveau[l] = {}
      for c = 1, 16 do
        niveau[l][c] = 1
      end
    end

    -- on positionne aléatoirement les autres types de briques (solides, bonus/malus, etc.)
    local nbr
    math.randomseed(os.time())
    for nbr = 1, 16 do
      niveau[math.random(1,6)][math.random(1,16)] = math.random(2,8)
    end
  
    -- on positionne enfin la brique de victoire
    niveau[1][1] = 9
  
  
   elseif pChoix == 'niveaux' then
     niveau = {}
     for l = 1, #levels[pad.niveau].map do
       niveau[l] = {}
       for c = 1, #levels[pad.niveau].map[1] do
         niveau[l][c] = levels[pad.niveau].map[l][c]
       end
     end

  end
  
end


function BordBalle(pCoordo, pDir, pRadius)
  -- retourne la coordonnée du bord de la balle selon les coordo dans un axe et la direction du mouvement
  return pCoordo + (pDir * pRadius)

end

function love.load()

  largeur = love.graphics.getWidth()
  hauteur = love.graphics.getHeight()

  brique.hauteur = hauteur / 24
  brique.largeur = largeur / 16

  pad.y = hauteur - pad.hauteur
  Demarre()

end


function love.update(dt)
  
  if ecran == 'menu' and selection == true then
    
    sonMenu:setLooping(true)
    sonMenu:play()
    if choixMenu[menuSelec] == "aleatoire" or choixMenu[menuSelec] == "niveaux" then
      CreationNiveau(choixMenu[menuSelec])
      ecran = 'jeu'
    else 
      ecran = choixMenu[menuSelec]
    end
    selection = false
    sonMenu:stop()

  end

  if  ecran == 'aide' then

  end
  
  if ecran == 'jeu' then

    -- on place la raquette à la position de la souris
    pad.x = love.mouse.getX()
    if pad.x < pad.largeur/2 then
      pad.x = pad.largeur/2
    end
    if pad.x > largeur-pad.largeur/2 then
      pad.x = largeur-pad.largeur/2
    end  
    
    -- on teste si la balle dépasse les bords de la fenêtre
    if balle.colle == true then
      balle.x = pad.x
      balle.y = pad.y - balle.r
    else
      -- on mémorise la position de la balle pour le test de collision
      local x_pre = balle.x
      local y_pre = balle.y
      balle.x = balle.x + balle.vx * balle.dirx * dt
      balle.y = balle.y + balle.vy * balle.diry * dt

      -- on vérifie si collision avec brique
      bordx_balle = BordBalle(balle.x, balle.dirx, balle.r)
      bordy_balle = BordBalle(balle.y, balle.diry, balle.r)
      bordx_pre = BordBalle(x_pre, balle.dirx, balle.r)
      bordy_pre =BordBalle(y_pre, balle.diry, balle.r)
      
      local cpre = math.floor(bordx_pre / brique.largeur) + 1
      local lpre = math.floor((bordy_pre-16) / brique.hauteur) + 1
          
      local c = math.floor(bordx_balle / brique.largeur) + 1 
      local l = math.floor((bordy_balle-16) / brique.hauteur) + 1
     
            
      -- gestion des effets selon le type de brique touchée 
      if l >= 1 and l <= #niveau then
        if c >= 1 and c <= 16 then
          -- modification de la direction de rebond selon le bord ou axe d'impact
          if cpre >= 1 and cpre <= 16 then
            if niveau[l][cpre] ~= 0 then
              balle.diry = balle.diry * -1
            end
          end
          if lpre >= 1 and lpre <= #niveau then
            if niveau[lpre][c] ~= 0 then
              balle.dirx = balle.dirx * -1
            end
          end

          -- brique de différents niveaux de dureté (à 1 à 6), perdent un niveau de dureté à chaque collision
          if niveau[l][c] >= 1 and niveau[l][c] < 6 then
            pad.score = pad.score + niveau[l][c] * 10
            if niveau[l][c] > 1 then
              sonBriqueCollision:play()
            end
            niveau[l][c] = niveau[l][c] - 1
            if niveau[l][c] == 0 then
              sonBriqueDetruite:play()
              pad.nbriques = pad.nbriques + 1
            end
          
          -- briques indestructibles, rebond 
          elseif niveau[l][c] == 6 then
            sonBriqueDure:play()
          
          -- briques bonus
          elseif niveau[l][c] == 7 then
            sonBonus:play()
            -- détermine le bonus au hasard 
            local bonus = math.random(1, 3)
            -- si la balle n'est pas trop rapide, augmente la vitess de 25%
            if bonus == 1 and balle.vconst < 546 then
              balle.vconst = balle.vconst * 1.25 
            -- si le pad n'est pas trop large, augmente la largeur de 50% 
            elseif bonus == 2 and pad.largeur < 240 then
              pad.largeur = pad.largeur * 1.5
            -- balle supplémentaire
            elseif bonus == 3 then
              balle.nombre = balle.nombre + 1
            end
            -- élimine la brique 
            niveau[l][c] = 0
          
          -- briques malus
          elseif niveau[l][c] == 8 then
            sonMalus:play()
            -- détermine le malus au hasard 
            local malus = math.random(1, 3)
            -- si la balle n'est pas trop lente, diminue la vitesse de 25% 
            if malus == 1 and balle.vconst > 75 then
              balle.vconst = balle.vconst * .75
            -- si la raquette n'est pas trop étroite, réduit sa taille de 30%
            elseif malus == 2 and pad.largeur > 80 * .67 then
              pad.largeur = pad.largeur * .67
            -- perd une balle
            elseif malus == 3 then
              balle.nombre = balle.nombre - 1
            end
           -- supprime la brique
           niveau[l][c] = 0
          
          -- brique de victoire
          elseif niveau[l][c] == 9 then 
            pad.niveau = pad.niveau + 1
            if pad.niveau > #levels then
              ecran = "You win!" 
              pad.niveau = 1
            else
              balle.colle = true
              sonDemarre:play()
              CreationNiveau('niveaux')
            end
          end
        
        end
      end


      if balle.x > largeur - balle.r then
        balle.dirx = balle.dirx * -1 
        balle.x = largeur - balle.r
        sonMur:play()
      end

      if balle.x < balle.r then
        balle.dirx = balle.dirx * -1
        balle.x = balle.r
        sonMur:play()
      end

      if balle.y < balle.r then
        balle.diry = balle.diry * -1
        balle.y = balle.r
        sonMur:play()
      end


      if balle.y + balle.r >= pad.y and balle.colle == false  and pad.actif == true then
           -- le bord de la balle est au même niveau que la surface de la raquette
           -- on teste alors si la balle touche la raquette
        local zone = balle.r + pad.largeur/2
        if balle.x > pad.x - zone  and balle.x < pad.x + zone then
          -- on modifie l'angle en fonction de où ça tape sur la raquette (rebond plus "vertical" si tape au centre, plus "horizontal" si tape au bord)
          --
          sonPad:play()
         
          -- la balle repart du côté opposé du bord de la raquette qui l'a reçue
          if balle.x > pad.x then
            balle.dirx = -1
          else
            balle.dirx = 1
          end
          
          -- on détermine l'angle d'arrivée
          balle.angle = math.atan2(balle.vy, balle.vx)
          -- on détermine à quelle distance du centre de la raquetteça tape
          local ximpact = math.abs(balle.x - pad.x)*5/zone + 1
          -- on calcule le nouvel angle avec une fonction sigmoïde centrée sur pi/8 (déterminée empiriquement pour avoir le rebond voulu)
          balle.angle = 1/(1+math.exp(-4*(balle.angle - math.pi/8)))*math.pi/ximpact
          -- on corrige l'angle (si dépasse la verticale ou si trop ouvert, proche de l'horizontale)
          if balle.angle > math.pi/2 then 
            balle.angle = math.pi/2 - math.pi/20
          end
          if balle.angle < math.pi/12 then
            balle.angle = math.pi/12
          end
          -- si l'angle est très aigu, on inverse la direction x 
          if balle.angle < math.pi/8 then
            balle.dirx = balle.dirx * -1
          end
          -- on fait remonter la balle
          balle.diry = -1
          -- on calcule les nouvelles vitesses vert et horiz à partir de l'angle de rebond
          balle.vx = balle.vconst * math.cos(balle.angle)
          balle.vy = balle.vconst * math.sin(balle.angle)
          else
          -- si la balle n'est pas sur la raquette on perd la balle, on désactive la raquette
          pad.actif = false 
          sonMiss:play()
        end
      end
      -- enfin si la balle sort de l'écran, on la recolle et réinitialise
      if balle.y > hauteur then
        balle.nombre = balle.nombre - 1
        pad.actif = true
        balle.colle = true
        balle.angle = math.pi/4
        balle.diry = -1
      end
    end

    if balle.nombre <= 0 then
      sonGameOver:play()
      ecran = 'You lose!'
    end

  end

  if ecran == 'You lose!' or ecran == 'You win!' then
 
    if restart == true then
      ecran = 'menu'
      Demarre()
    end

  end

  if ecran == 'quit' then

    love.event.quit()

  end

end


function love.draw()
  

  if ecran == "menu" then

    font = love.graphics.newFont("Fontes/PressStart2P.ttf", 40)
    love.graphics.setFont(font)
    love.graphics.setColor(.6, .6, 1)
    title='Casse-brique' 
    love.graphics.print(title, largeur/2 - font:getWidth(title)/2, hauteur/2-200)
    font = love.graphics.newFont("Fontes/PressStart2P.ttf", 12)
    love.graphics.setFont(font)
    instruct = 'make your choice with \'space\', confirm with \'enter\''
    love.graphics.print(instruct, largeur/2 - font:getWidth(instruct)/2, hauteur/2 - 60)
    love.graphics.setColor(1, 1, 1)

    font = love.graphics.newFont("Fontes/PressStart2P.ttf", 16)
    love.graphics.setFont(font)
    
    -- ajouter le changmeent de couleur en fonction de la selection plus petit triangle
    
    if menuSelec == 1 then
      love.graphics.setColor(.7, 0, 0)
    end
    love.graphics.print("Classic game (several levels)", 100, hauteur/2 - 20)
    love.graphics.setColor(1, 1, 1)

    if menuSelec == 2 then
      love.graphics.setColor(.7, 0, 0)
    end
    love.graphics.print("Short game (one level randomly generated)", 100, hauteur/2)
    love.graphics.setColor(1, 1, 1)

    if menuSelec == 3 then
      love.graphics.setColor(.7, 0, 0)
    end
    love.graphics.print("Help page", 100, hauteur/2 + 20)
    love.graphics.setColor(1, 1, 1)

    if menuSelec == 4 then
      love.graphics.setColor(.7, 0, 0)
    end
    love.graphics.print("Quit", 100, hauteur/2 + 40)
    love.graphics.setColor(1, 1, 1)

  end
  
  if ecran == "aide" then
    
    font = love.graphics.newFont("Fontes/PressStart2P.ttf", 24)
    love.graphics.setFont(font)
    love.graphics.setColor(.6, .6, 1)
    title = "How to play"
    love.graphics.print(title, largeur/2 - font:getWidth(title)/2, 30)
    love.graphics.setColor(1, 1, 1)

    font = love.graphics.newFont("Fontes/PressStart2P.ttf", 12)
    love.graphics.setFont(font)
    love.graphics.print("Use the mouse to move the pad horizontally and bounce the ball", 20, 80)
    love.graphics.print("against the brick to break them. Click to launch the ball.", 20, 100)
    love.graphics.setColor(.9, .85, .3)
    love.graphics.print("Yellow brick", 20, 140) 
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Hit the yellow brick to reach the next level.", 20, 160)
    love.graphics.print("White bricks", 20, 200)
    love.graphics.print("Basic bricks, one hit is enough to destroy them", 20, 220)
    love.graphics.setColor(1, 1/5, 1/5)
    love.graphics.print("Red bricks", 20, 260)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Stronger bricks, hit them several times to break them. The more", 20, 280)
    love.graphics.print("they lose their reddish tint, the closest they are to destruction", 20, 300)
    love.graphics.setColor(.7, .7, .7)
    love.graphics.print("Grey bricks", 20, 340)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Those bricks are unbreakable.", 20, 360)
    love.graphics.setColor(0, .7, 0)
    love.graphics.print("Green bricks", 20, 400)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Random bonus: ball acceleration, larger pad, extra ball", 20, 420)
    love.graphics.setColor(.2, .2, 1)
    love.graphics.print("Blue bricks", 20, 460)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Random malus : ball deceleration, shrink pad, lose a ball", 20, 480)
    love.graphics.setColor(.6, .6, 1) 
    instruct = "\'enter\' to get back to menu."
    love.graphics.print(instruct, largeur/2 - font:getWidth(instruct)/2, 540)
    love.graphics.setColor(1, 1, 1)

  end

  if ecran == "jeu" then

    local l, c
    local bx, by = 0, 16
    for l = 1, #niveau do
      bx = 0
      for c = 1, 16 do

        if niveau[l][c] > 0 and niveau[l][c] < 6 then
          -- Dessine une brique
          love.graphics.setColor(1, 1/niveau[l][c], 1/niveau[l][c])
          love.graphics.rectangle('fill', bx+1, by+1, brique.largeur-2, brique.hauteur-2)
          love.graphics.setColor(1, 1, 1)
        elseif niveau[l][c] == 6 then
          love.graphics.setColor(.7, .7, .7)
          love.graphics.rectangle('fill', bx+1, by+1, brique.largeur-2, brique.hauteur-2)
          love.graphics.setColor(1, 1, 1)
        elseif niveau[l][c] == 7 then
          love.graphics.setColor(0, .7, 0)
          love.graphics.rectangle('fill', bx+1, by+1, brique.largeur-2, brique.hauteur-2)
          love.graphics.setColor(1, 1, 1)
        elseif niveau[l][c] == 8 then
          love.graphics.setColor(.2, .2, 1)
          love.graphics.rectangle('fill', bx+1, by+1, brique.largeur-2, brique.hauteur-2)
          love.graphics.setColor(1, 1, 1)
        elseif niveau[l][c] == 9 then
          love.graphics.setColor(.9, .85, .3)
          love.graphics.rectangle('fill', bx+1, by+1, brique.largeur-2, brique.hauteur-2)
          love.graphics.setColor(1, 1, 1)

        end

        bx = bx + brique.largeur   
      end
      by = by + brique.hauteur
    end
    
    love.graphics.rectangle('fill', pad.x - pad.largeur/2, pad.y, pad.largeur, pad.hauteur)

    love.graphics.circle('fill', balle.x, balle.y, balle.r)
    
    font = love.graphics.newFont("Fontes/PressStart2P.ttf", 12)
    love.graphics.setFont(font)
    
    love.graphics.setColor(.7, .7, .7 )
    love.graphics.print('Balls: '..tostring(balle.nombre)..'      Score: '..tostring(pad.score)..'      Broken bricks: '..tostring(pad.nbriques)..'       Level: '..tostring(pad.niveau))
    love.graphics.setColor(1, 1, 1)

  end

  if ecran == 'You lose!' or ecran == 'You win!' then
    
    font = love.graphics.newFont("Fontes/PressStart2P.ttf", 22)
    love.graphics.setFont(font)
    finalText = ecran..' score : '..tostring(pad.score)
    love.graphics.print(finalText, largeur/2 - font:getWidth(finalText)/2 , hauteur/2 - 40)
    finalText = 'Click to get back to menu'
    love.graphics.print(finalText, largeur/2 - font:getWidth(finalText)/2, hauteur/2)
  end
  
end


function love.mousepressed(x, y, n)
  
  --C'est une bonne pratique de mettre en place sur ce type de fonction qui s'exécutent sans arrêt de mettre au début une condition pour faire en sorte que le contenu de la fonction ne s'exécute qu'une seule fois, sinon on a des "dérapages" ou "clicks multiples" même si on appuie qu'un bref instant
  if ecran == 'jeu' then
    if balle.colle == true then
      balle.colle = false
      balle.vx = balle.vconst * math.cos(balle.angle)
      balle.vy = balle.vconst * math.cos(balle.angle)
      sonPad:play()
    end
  end

  if ecran == 'You lose!' or ecran == 'You win!' then
    restart = true
  end

end


function love.keypressed(key)

  if key == 'escape' then
    ecran = 'quit'
  end
  
  if ecran == 'menu' then
    -- maj d'une variable pour le choix, et une autre pour la sélection
    --
    if key == 'space' then
      menuSelec = (menuSelec % 4)+1
    end
    if key == 'return' then
      selection = true
    end
  end

  if ecran == 'aide' then
    if key == 'return' then
      ecran = 'menu'
    end
  end

-- for debugging purpose only (print the level table)
--  if key == 'n' then
--    local l, c
--    for l = 1, #niveau do
--      for c = 1, #niveau[l] do
--        io.write(niveau[l][c])
--      end
--      io.write('\n')
--    end
--  end

end
