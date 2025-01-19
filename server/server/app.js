const express = require('express');
const fs = require('fs');
const path = require('path');
const cors = require('cors');

const app = express();
const port = 3000;

app.use(cors()); 

// Middleware para analizar JSON en las solicitudes POST
app.use(express.json());

// Continguts estàtics (carpeta public)
app.use(express.static('public'));

// Ruta POST: Demanar categories
app.post('/categories', async (req, res) => {
    try {
      const data = JSON.parse(fs.readFileSync(path.join(__dirname, 'data', 'data.json'), 'utf-8'));
      const categories = {
        categories: data.categories.map((cat, index) => ({
          id: index.toString(),
          name: cat.name
        }))
      };
      res.json(categories);
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: 'Error loading categories.' });
    }
  });
  


// Ruta POST: Demanar items d'una categoria
app.post('/items', async (req, res) => {
  
    try {
      const { categoryId, search } = req.body;
  
      const data = JSON.parse(fs.readFileSync(path.join(__dirname, 'data', 'data.json'), 'utf-8'));
  
      const category = data.categories.find(cat => cat.id == String(categoryId));
  
      if (category) {
        // Filtrar los artículos según el texto de búsqueda si se proporcionó
        let filteredItems = category.items;
  
        if (search && search.trim() !== '') {
          filteredItems = filteredItems.filter(item => item.name.toLowerCase().includes(search.toLowerCase()));
        }
  
        res.json({ items: filteredItems });
      } else {
        res.status(404).json({ error: 'Category not found.' });
      }
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: 'Error loading items.' });
    }
  }); 
  

// Ruta POST: Demanar informació d'un ítem / buscar
app.post('/item-info', async (req, res) => {
    try {
        const { itemName } = req.body;
        const data = JSON.parse(fs.readFileSync(path.join(__dirname, 'data', 'data.json'), 'utf-8'));
        const category = data.categories.find(cat =>
            cat.items.some(item => item.name === itemName)
        );
        if (category) {
            const item = category.items.find(item => item.name === itemName);
            res.json(item);
        } else {
            res.status(404).json({ error: 'Item not found.' });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error loading item information.' });
    }
});


// Ruta GET: Retornar la imatge d'un ítem
app.get('/images/:imageName', (req, res) => {
    const imageName = req.params.imageName;
    const imagePath = path.join(__dirname, 'public', 'images', imageName);
    if (fs.existsSync(imagePath)) {
        res.sendFile(imagePath);
    } else {
        res.status(404).json({ error: 'Image not found.' });
    }
});

// Activar el servidor
const httpServer = app.listen(port, appListen)
function appListen () {
    console.log(`Example app listening on: http://0.0.0.0:${port}`)
}

// Aturar el servidor correctament 
process.on('SIGTERM', shutDown);
process.on('SIGINT', shutDown);
function shutDown() {
    // Executar aquí el codi previ al tancament de servidor
    
    console.log('Received kill signal, shutting down gracefully');
    httpServer.close()
    process.exit(0);
}
