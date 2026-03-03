This **Game Design Document (GDD)** outlines the vision for a calm, Montessori-inspired educational application for children aged 2–4. The project bridges the tactile feedback of classic toy laptops (like V-Tech) with the clean, minimalist aesthetic of physical wooden toys.

# ---

**📜 Game Design Document: *The Wooden Shelf (Working Title)***

## **1\. Executive Summary**

* **Core Concept:** A digital compilation of mini-games that look, sound, and feel like high-quality wooden toys.  
* **Target Audience:** Toddlers (2–4 years old).  
* **Primary Goals:** Early literacy, numeracy, and environmental awareness through "Control of Error" (self-correction).  
* **Platform:** Focus on Touch Screens (Tablets/Phones).  
* **Language Support:** English and Spanish (Global Toggle).

## ---

**2\. Aesthetic & UX Philosophy**

* **Visual Style:** "Digital Woodshop." High-quality textures (Birch/Oak), watercolor illustrations, and a pastel palette (Sage, Terracotta, Cream).  
* **Sound Design:** Organic and acoustic. Wood-on-wood "clacks," paper rustles, and real animal recordings. No background music; only low-volume ambient nature sounds.  
* **Interface:** Zero text-based navigation for the child. No "Game Over" screens or high-energy "Level Up" animations.

## ---

**3\. The Main Menu: "The Shelf"**

* **Layout:** A 2x2 Static Grid of wooden blocks sitting on a birch shelf.  
* **Navigation:** \* **Phase 1:** 4 blocks centered.  
  * **Future:** Paginated 2x2 grid (swipe to the next shelf). Empty slots remain empty (no "Coming Soon" icons).  
* **The Icons:**  
  * **Alphabet:** Block with 'A'.  
  * **Animals:** Block with a Dog silhouette.  
  * **Numbers:** Block with '1'.  
  * **Universe:** Block with a Moon.

## ---

**4\. Activity Modules**

### **4.1. Alphabet (Phonetic Flashcards)**

* **Logic:** English (26 cards), Spanish (27 cards including **Ñ**).  
* **Interaction:** \* **Tap:** Flip the card horizontally.  
  * **Swipe:** Move to the next/previous letter.  
* **Content:**  
  * Side A: Letter with audio of the phonetic sound \+ letter name.  
  * Side B: Watercolor object matching the letter (e.g., A \- *Apple* / *Avión*).

### **4.2. Animals (The Farm Scroll)**

* **Logic:** A horizontal panorama of a farm landscape.  
* **Interaction:** \* **Horizontal Drag:** Explore the environment.  
  * **Tap Animal:** Trigger a "bounce" animation.  
* **Audio:** Natural animal sound (Moo) $\\rightarrow$ Spoken name (Vaca/Cow).  
* **Animals:** Cow, dog, cat, sheep, horse, hen, rooster, duck, pig

### **4.3. Numbers (Fruit Basket)**

* **Logic:** Randomized counting challenges (1–10).  
* **Interaction:** \* **The Tray:** Shows $X$ amount of random fruit (e.g., 5 Grapes).  
  * **The Selection:** 3 wooden number blocks below the tray.  
* **Control of Error:** If an incorrect number is tapped, the block **sinks into the table** and becomes disabled. The child must find the correct number to proceed.  
* **Fruits:** Apple, banana, pineapple, orange, lime, watermelon

### **4.4. Universe (The Cosmic Orrery)**

* **Logic:** A simplified heliocentric model.  
* **Visuals:** Sun (Center), Earth (Orbiting Sun), Moon (Orbiting Earth).  
* **Interaction:** Observation-focused. Tapping an object plays its name and a unique acoustic chime.

## ---

**5\. Global Systems**

### **5.1. Language System**

* **Switching:** Controlled via Parent Gate.  
* **Dynamic Assets:** Swapping between EN and ES updates audio files and specific visual assets (like the Alphabet deck size and the fruit/animal names).

### **5.2. Parental Gate & Navigation**

* **Home Button:** A wooden house icon (Top-Left). Requires a **3-second long press** to activate.  
* **Settings Access:** A discreet gear icon with a cognitive lock (e.g., "Hold for 5 seconds" or "Slide shape to target") to prevent child access.

## ---

**6\. Technical Requirements (Product-First)**

* **State Management:** The app must remember the selected language globally.  
* **Asset Management:** High-resolution textures are required to maintain the "premium wooden toy" feel on retina displays.  
* **Input:** Multi-touch should be disabled within activities to prevent "fat-finger" errors; only single-point contact is registered for primary actions.