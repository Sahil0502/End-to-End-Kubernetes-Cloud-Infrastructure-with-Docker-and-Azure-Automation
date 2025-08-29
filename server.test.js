const request = require('supertest');
const app = require('./server');

describe('API Endpoints', () => {
  test('GET / should return welcome message', async () => {
    const response = await request(app)
      .get('/')
      .expect(200);
    
    expect(response.body.message).toContain('Welcome to Kubernetes Azure Infrastructure Demo');
  });

  test('GET /health should return health status', async () => {
    const response = await request(app)
      .get('/health')
      .expect(200);
    
    expect(response.body.status).toBe('healthy');
    expect(response.body).toHaveProperty('timestamp');
    expect(response.body).toHaveProperty('uptime');
  });

  test('GET /api/info should return system info', async () => {
    const response = await request(app)
      .get('/api/info')
      .expect(200);
    
    expect(response.body.service).toBe('k8s-azure-app');
    expect(response.body).toHaveProperty('hostname');
    expect(response.body).toHaveProperty('nodeVersion');
  });
});
