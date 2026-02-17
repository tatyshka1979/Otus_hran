#!/bin/bash
# Скрипт для полного удаления всех веток feature/* (локальных и в origin)

# Проверяем, что пользователь не находится на удаляемой ветке
current_branch=$(git branch --show-current)
if [[ $current_branch == feature/* ]]; then
  echo "Вы находитесь в ветке $current_branch. Переключитесь на main или develop перед удалением."
  exit 1
fi

# Обновляем список веток
git fetch --all --prune

# Находим все локальные ветки feature/*
local_branches=$(git branch | grep 'feature/' | sed 's/^[ *]*//')

# Находим все удалённые ветки feature/*
remote_branches=$(git branch -r | grep 'origin/feature/' | sed 's/^ *origin\///')

# Объединяем и удаляем дубликаты
branches=$(echo -e "${local_branches}\n${remote_branches}" | sort -u | grep -v '^$')

# Проверка на пустой список
if [ -z "$branches" ]; then
  echo "Ветки feature/* не найдены ни локально, ни на origin."
  exit 0
fi

echo "Будут удалены следующие ветки:"
echo "$branches"
echo

read -p "Удалить эти ветки (y/n)? " confirm
if [[ "$confirm" != "y" ]]; then
  echo "Операция отменена."
  exit 0
fi

for branch in $branches; do
  echo "Удаление ветки $branch ..."

  # Удаляем локальную ветку (если есть)
  git branch -D "$branch" 2>/dev/null

  # Удаляем удалённую ветку
  git push origin --delete "$branch" 2>/dev/null || git push origin :"$branch" 2>/dev/null
done

echo "Все ветки feature/* удалены локально и на origin."

echo ""
echo "========================================="
echo "Выполнение hard-reset ветки branch_sync_hran..."
echo "========================================="

# Находим коммит с описанием "Создание хранилища конфигурации" в ветке develop
commit_hash=$(git log develop --all-match --grep="Создание хранилища конфигурации" --format="%H" -n 1)

if [ -z "$commit_hash" ]; then
  echo "Ошибка: Коммит с описанием 'Создание хранилища конфигурации' не найден в ветке develop."
  exit 1
fi

echo "Найден коммит: $commit_hash"
echo "Описание: $(git log --format=%B -n 1 $commit_hash | head -n 1)"
echo ""

read -p "Выполнить hard-reset ветки branch_sync_hran до этого коммита и force push? (y/n): " confirm_reset
if [[ "$confirm_reset" != "y" ]]; then
  echo "Операция hard-reset отменена."
  exit 0
fi

# Переключаемся на ветку branch_sync_hran
git checkout branch_sync_hran

if [ $? -ne 0 ]; then
  echo "Ошибка: Не удалось переключиться на ветку branch_sync_hran."
  exit 1
fi

# Выполняем hard-reset до найденного коммита
git reset --hard "$commit_hash"

if [ $? -ne 0 ]; then
  echo "Ошибка: Не удалось выполнить hard-reset."
  exit 1
fi

echo "Hard-reset выполнен успешно."

# Выполняем force push
git push origin branch_sync_hran --force

if [ $? -ne 0 ]; then
  echo "Ошибка: Не удалось выполнить force push."
  exit 1
fi

echo "Force push выполнен успешно."
echo "Ветка branch_sync_hran успешно сброшена до коммита '$commit_hash'."

git checkout -B "storage_1c" "origin/storage_1c"
