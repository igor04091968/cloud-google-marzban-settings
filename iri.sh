#!/bin/bash
# Скрипт для настройки SSH-доступа на сервере iri1968.dpdns.org для пользователя igor.

# Создаем директорию .ssh, если она не существует
mkdir -p /home/igor/.ssh

# Добавляем публичный ключ в файл authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC12yt6USMAgZ40qjEYielLmQAQkGF2iT6Ff0aCedT6iySrzd5PoJuXv4DZTE5iIwCCINOUz1d+kdYSg79ect5MC9bqfwHNJXSCrJLSJbrmCkOQ9b/dY6noBzbiap7py2srHVnfsOGXln9rJlikX43nTzcpjs8ocPbLNkrQloYW2QJFQ9Pltjd7KacZp2ZKJ97zay3M8MsSZQnLCM+NHagudE1dXgIbNN17vz4N3fq9Hjs7+UWIRVNduW998/OrZoEIpYYQ//6+Ox14m3GLTXy9Njp1DF+LrBdV3E7zKcXpuDdNt8fUu3Ad8JQQV9E/isxcBU4/ugtiwFKSyoTiyqquk75NPRAAmMiXAqK817O7JpqGPme0CXOGoRnaQucxMN6l9CT215ne80Y1FtnvRRfvyI6v7ayz6O1Katx84vK+mgwrQpHPGqqVifEEMjGR/c+qwjyoVFbecsvk2sMnrsYKOwZVUOf2L0YKTuq34jQndhHOJSEpK4gOWFC2JCzdorenTyPt/XRU/Ebm3voyHkITUISVauORWGxKi1s6EEbqEfD7dH7Yij9YIWscJ6RphJV34KNCR8bUUM+JVEWAS0n6PjMIopAbbZ7FhRpGo6hzH7Uh0s7+n//hhJDBY1lzKfSVBARBEeBS51oOIkG5BEqL8VCb17jYxtWpLpigPuSgwQ== igor04091968@users.noreply.github.com" >> /home/igor/.ssh/authorized_keys

# Устанавливаем правильные права доступа
chmod 700 /home/igor/.ssh
chmod 600 /home/igor/.ssh/authorized_keys

echo "Настройка SSH-ключа завершена."
