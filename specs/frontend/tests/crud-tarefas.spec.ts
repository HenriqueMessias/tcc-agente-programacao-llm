// specs/frontend/tests/crud-tarefas.spec.ts
import { test, expect } from '@playwright/test';

test.describe('CRUD de Tarefas - Validação de DOM', () => {
  
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('Deve exibir campo de input, botão adicionar e lista vazia', async ({ page }) => {
    await expect(page.locator('[data-testid="task-input"]')).toBeVisible();
    await expect(page.locator('[data-testid="add-task-button"]')).toBeVisible();
    await expect(page.locator('[data-testid="task-list"]')).toBeVisible();
    await expect(page.locator('[data-testid="task-item"]')).toHaveCount(0);
    await expect(page.locator('[data-testid="pending-count"]')).toContainText('0 tarefa(s) pendente(s)');
  });

  test('Adicionar uma tarefa', async ({ page }) => {
    const input = page.locator('[data-testid="task-input"]');
    const addButton = page.locator('[data-testid="add-task-button"]');
    
    await input.fill('Estudar TDD');
    await addButton.click();
    
    const taskItem = page.locator('[data-testid="task-item"]');
    await expect(taskItem).toHaveCount(1);
    await expect(taskItem.locator('[data-testid="task-text"]')).toHaveText('Estudar TDD');
    await expect(taskItem.locator('[data-testid="task-checkbox"]')).not.toBeChecked();
    
    await expect(input).toHaveValue('');
    await expect(page.locator('[data-testid="pending-count"]')).toContainText('1 tarefa(s) pendente(s)');
  });

  test('Marcar tarefa como concluída altera estilo', async ({ page }) => {
    await page.locator('[data-testid="task-input"]').fill('Tarefa teste');
    await page.locator('[data-testid="add-task-button"]').click();
    
    const taskText = page.locator('[data-testid="task-text"]');
    const checkbox = page.locator('[data-testid="task-checkbox"]');
    
    await checkbox.check();
    await expect(taskText).toHaveCSS('text-decoration', /line-through/);
    await expect(taskText).toHaveCSS('color', 'rgb(136, 136, 136)');
    
    await expect(page.locator('[data-testid="pending-count"]')).toContainText('0 tarefa(s) pendente(s)');
    
    await checkbox.uncheck();
    await expect(taskText).not.toHaveCSS('text-decoration', /line-through/);
    await expect(page.locator('[data-testid="pending-count"]')).toContainText('1 tarefa(s) pendente(s)');
  });

  test('Excluir tarefa remove item do DOM', async ({ page }) => {
    await page.locator('[data-testid="task-input"]').fill('T1');
    await page.locator('[data-testid="add-task-button"]').click();
    await page.locator('[data-testid="task-input"]').fill('T2');
    await page.locator('[data-testid="add-task-button"]').click();
    
    const items = page.locator('[data-testid="task-item"]');
    await expect(items).toHaveCount(2);
    
    await items.nth(0).locator('[data-testid="delete-task-button"]').click();
    
    await expect(items).toHaveCount(1);
    await expect(page.locator('[data-testid="task-text"]')).toHaveText('T2');
    await expect(page.locator('[data-testid="pending-count"]')).toContainText('1 tarefa(s) pendente(s)');
  });

  test('Layout básico e responsividade', async ({ page }) => {
    const body = page.locator('body');
    await expect(body).toHaveCSS('background-color', 'rgb(249, 249, 249)');
    
    const addBtn = page.locator('[data-testid="add-task-button"]');
    await expect(addBtn).toHaveCSS('background-color', 'rgb(0, 123, 255)');
    
    await page.locator('[data-testid="task-input"]').fill('X');
    await addBtn.click();
    const delBtn = page.locator('[data-testid="delete-task-button"]');
    await expect(delBtn).toHaveCSS('background-color', 'rgb(220, 53, 69)');
  });

  test('Não adicionar tarefa com campo vazio', async ({ page }) => {
    await page.locator('[data-testid="add-task-button"]').click();
    await expect(page.locator('[data-testid="task-item"]')).toHaveCount(0);
  });

});
