// ─────────────────────────────────────────────────────────────────────────────
// Category Controller — System Defaults + User Customs
// ─────────────────────────────────────────────────────────────────────────────

const prisma = require('../config/prisma');
const { success, created, error } = require('../utils/apiResponse');

// ─── List Categories ────────────────────────────────────────────────────────

async function getCategories(req, res) {
  const userId = req.user.id;

  // System defaults (userId IS null) + user's custom categories
  const categories = await prisma.category.findMany({
    where: {
      OR: [{ userId: null, isDefault: true }, { userId }],
      isActive: true,
    },
    orderBy: [{ isDefault: 'desc' }, { name: 'asc' }],
    select: {
      id: true,
      name: true,
      icon: true,
      color: true,
      isDefault: true,
      userId: true,
    },
  });

  return success(res, categories);
}

// ─── Create Custom Category ─────────────────────────────────────────────────

async function createCategory(req, res) {
  const { name, icon, color } = req.body;

  if (!name || !name.trim()) {
    return error(res, 'name is required', 400);
  }
  if (!icon) {
    return error(res, 'icon is required', 400);
  }
  if (!color || !/^#[0-9A-Fa-f]{6}$/.test(color)) {
    return error(res, 'color must be a valid hex code (e.g. #FF6B6B)', 400);
  }

  // Check for duplicate name under this user
  const existing = await prisma.category.findFirst({
    where: {
      userId: req.user.id,
      name: { equals: name.trim(), mode: 'insensitive' },
    },
  });
  if (existing) {
    return error(res, 'You already have a category with this name', 409);
  }

  const category = await prisma.category.create({
    data: {
      name: name.trim(),
      icon,
      color,
      userId: req.user.id,
      isDefault: false,
      isActive: true,
    },
  });

  return created(res, category, 'Category created');
}

// ─── Update Custom Category ─────────────────────────────────────────────────

async function updateCategory(req, res) {
  const { id } = req.params;
  const { name, icon, color } = req.body;

  const existing = await prisma.category.findUnique({ where: { id } });
  if (!existing) {
    return error(res, 'Category not found', 404);
  }

  // Can't edit system defaults
  if (existing.isDefault) {
    return error(res, 'System default categories cannot be edited', 403);
  }
  if (existing.userId !== req.user.id) {
    return error(res, 'Access denied', 403);
  }

  // Validate color if provided
  if (color && !/^#[0-9A-Fa-f]{6}$/.test(color)) {
    return error(res, 'color must be a valid hex code (e.g. #FF6B6B)', 400);
  }

  const category = await prisma.category.update({
    where: { id },
    data: {
      ...(name && { name: name.trim() }),
      ...(icon && { icon }),
      ...(color && { color }),
    },
  });

  return success(res, category, 'Category updated');
}

// ─── Soft Delete Custom Category ────────────────────────────────────────────

async function deleteCategory(req, res) {
  const { id } = req.params;

  const existing = await prisma.category.findUnique({ where: { id } });
  if (!existing) {
    return error(res, 'Category not found', 404);
  }
  if (existing.isDefault) {
    return error(res, 'System default categories cannot be deleted', 403);
  }
  if (existing.userId !== req.user.id) {
    return error(res, 'Access denied', 403);
  }

  // Soft deactivate — keep for historical expenses
  const category = await prisma.category.update({
    where: { id },
    data: { isActive: false },
  });

  return success(res, category, 'Category deactivated');
}

module.exports = { getCategories, createCategory, updateCategory, deleteCategory };
