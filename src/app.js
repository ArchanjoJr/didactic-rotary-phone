const express = require('express')
const morgan = require('morgan')

const app = express()

app.use(morgan(':method :url :status :res[content-length] - :response-time ms'))

app.get('/ping', (req, res) => {
  res.status(200).json({'message': 'pong', 'random': `${Math.random()}` });
})

app.get('/status', (req, res) => {
  res.status(200).json({'success': 'true', 'random': `${Math.random()}` });
})

app.listen(3000, () => console.log('listenning'))