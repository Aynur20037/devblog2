import { useState, useEffect } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import axios from 'axios'
import { FiEye, FiCalendar, FiUser, FiTag } from 'react-icons/fi'
import './Home.css'

const Home = () => {
  const [articles, setArticles] = useState([])
  const [categories, setCategories] = useState([])
  const [tags, setTags] = useState([])
  const [loading, setLoading] = useState(true)
  const [pagination, setPagination] = useState({})
  const [searchParams] = useSearchParams()
  const [currentPage, setCurrentPage] = useState(1)

  const search = searchParams.get('search')
  const category = searchParams.get('category')
  const tag = searchParams.get('tag')

  useEffect(() => {
    fetchArticles()
    fetchCategories()
    fetchTags()
  }, [currentPage, search, category, tag])

  const fetchArticles = async () => {
    try {
      setLoading(true)
      const params = {
        page: currentPage,
        limit: 10
      }
      if (search) params.search = search
      if (category) params.category = category
      if (tag) params.tag = tag

      const response = await axios.get('/api/articles', { params })
      setArticles(response.data.articles)
      setPagination(response.data.pagination)
    } catch (error) {
      console.error('Ошибка загрузки статей:', error)
    } finally {
      setLoading(false)
    }
  }

  const fetchCategories = async () => {
    try {
      const response = await axios.get('/api/categories')
      setCategories(response.data)
    } catch (error) {
      console.error('Ошибка загрузки категорий:', error)
    }
  }

  const fetchTags = async () => {
    try {
      const response = await axios.get('/api/tags')
      setTags(response.data)
    } catch (error) {
      console.error('Ошибка загрузки тегов:', error)
    }
  }

  const formatDate = (date) => {
    return new Date(date).toLocaleDateString('ru-RU', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })
  }

  if (loading) {
    return <div className="loading">Загрузка статей...</div>
  }

  return (
    <div className="home">
      <div className="container">
        {/* Hero Section с изображениями */}
        <div className="hero-section">
          <div className="hero-content">
            <h1>Добро пожаловать в DevBlog</h1>
            <p>Платформа для технических блогов и изучения программирования</p>
            <div className="hero-images">
              <div className="hero-image-card">
                <div className="hero-image-placeholder coding">
                  <span>💻</span>
                  <p>Программирование</p>
                </div>
              </div>
              <div className="hero-image-card">
                <div className="hero-image-placeholder learning">
                  <span>📚</span>
                  <p>Обучение</p>
                </div>
              </div>
              <div className="hero-image-card">
                <div className="hero-image-placeholder community">
                  <span>👥</span>
                  <p>Сообщество</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className="home-layout">
          <div className="home-main">
            {search && (
              <div className="search-results">
                <h2>Результаты поиска: "{search}"</h2>
              </div>
            )}

            {articles.length === 0 ? (
              <div className="no-articles">
                <p>Статьи не найдены</p>
              </div>
            ) : (
              articles.map((article) => (
                <article key={article.id} className="article-card">
                  {article.coverImage && (
                    <div className="article-cover">
                      <img src={article.coverImage} alt={article.title} />
                    </div>
                  )}
                  <div className="article-content">
                    <div className="article-meta">
                      {article.category && (
                        <Link
                          to={`/?category=${article.category.id}`}
                          className="article-category"
                        >
                          {article.category.name}
                        </Link>
                      )}
                      <span className="article-date">
                        <FiCalendar /> {formatDate(article.createdAt)}
                      </span>
                      <span className="article-views">
                        <FiEye /> {article.views}
                      </span>
                    </div>
                    <h2>
                      <Link to={`/article/${article.slug}`}>{article.title}</Link>
                    </h2>
                    {article.excerpt && (
                      <div className="article-excerpt">
                        {article.excerpt}
                      </div>
                    )}
                    <div className="article-footer">
                      <Link to={`/user/${article.author.id}`} className="article-author">
                        {article.author.avatar ? (
                          <img src={article.author.avatar} alt={article.author.username} />
                        ) : (
                          <FiUser />
                        )}
                        <span>{article.author.username}</span>
                      </Link>
                      {article.tags && article.tags.length > 0 && (
                        <div className="article-tags">
                          {article.tags.map((tag) => (
                            <Link
                              key={tag.id}
                              to={`/?tag=${tag.slug}`}
                              className="article-tag"
                            >
                              <FiTag /> {tag.name}
                            </Link>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>
                </article>
              ))
            )}

            {pagination.pages > 1 && (
              <div className="pagination">
                <button
                  onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                  disabled={currentPage === 1}
                >
                  Назад
                </button>
                <span>
                  Страница {currentPage} из {pagination.pages}
                </span>
                <button
                  onClick={() => setCurrentPage(p => Math.min(pagination.pages, p + 1))}
                  disabled={currentPage === pagination.pages}
                >
                  Вперед
                </button>
              </div>
            )}
          </div>

          <aside className="home-sidebar">
            <div className="sidebar-section">
              <h3>Категории</h3>
              <ul className="category-list">
                {categories.map((cat) => (
                  <li key={cat.id}>
                    <Link to={`/?category=${cat.id}`}>
                      {cat.name} ({cat.articles?.length || 0})
                    </Link>
                  </li>
                ))}
              </ul>
            </div>

            <div className="sidebar-section">
              <h3>Популярные теги</h3>
              <div className="tag-cloud">
                {tags.slice(0, 20).map((tag) => (
                  <Link
                    key={tag.id}
                    to={`/?tag=${tag.slug}`}
                    className="tag-item"
                  >
                    {tag.name}
                  </Link>
                ))}
              </div>
            </div>
          </aside>
        </div>
      </div>
    </div>
  )
}

export default Home

